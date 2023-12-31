#!/bin/bash

# Check if the script is being run with sudo
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null; then
    echo "jq is not installed. Attempting to install..."
    # Determine the package manager and install jq
    if command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y jq
    elif command -v yum >/dev/null; then
        sudo yum install -y jq
    elif command -v dnf >/dev/null; then
        sudo dnf install -y jq
    else
        echo "Could not determine package manager. Please install jq manually."
        exit 1
    fi
    # Verify if jq is installed after the attempt
    if ! command -v jq >/dev/null; then
        echo "Failed to install jq. Please install it manually and run the script again."
        exit 1
    fi
fi

# Function to validate user input for record number
validate_number() {
  local num=$1
  [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= index - 1 ))
}

# Ask the user for Cloudflare API Token/Key, Email (if API Key is used), and Zone ID
read -p "Enter your Cloudflare API Token/Key: " cf_api_key_or_token
while : ; do
    read -p "Are you using API Token (t) or API Key (k)? " api_type
    if [ "$api_type" = "t" ] || [ "$api_type" = "k" ]; then
        break
    else
        echo "Invalid choice. Please select either 't' for Token or 'k' for Key."
    fi
done
if [ "$api_type" = "k" ]; then
  read -p "Enter your Cloudflare Email Address: " cf_email
fi
read -p "Enter your Cloudflare Zone ID: " cf_zone_id

# Fetch DNS records
if [ "$api_type" = "t" ]; then
    dns_response=$(curl --silent --request GET \
      --url "https://api.cloudflare.com/client/v4/zones/${cf_zone_id}/dns_records" \
      --header "Authorization: Bearer ${cf_api_key_or_token}" \
      --header "Content-Type: application/json")
else
    dns_response=$(curl --silent --request GET \
      --url "https://api.cloudflare.com/client/v4/zones/${cf_zone_id}/dns_records" \
      --header "X-Auth-Email: ${cf_email}" \
      --header "X-Auth-Key: ${cf_api_key_or_token}" \
      --header "Content-Type: application/json")
fi

# Check if the API response is successful and contains DNS records
if echo "$dns_response" | jq -e '.success == true' >/dev/null && echo "$dns_response" | jq -e '.result | length > 0' >/dev/null; then
  dns_records=$(echo $dns_response | jq -c '.result[]')
  index=1
  echo "DNS Records:"
  for record in $(echo "${dns_records}" | jq -r '. | @base64'); do
    decoded_record=$(echo "$record" | base64 --decode)
    name=$(echo $decoded_record | jq -r '.name')
    echo "$index: $name"
    index=$((index + 1))
  done

  while : ; do
    read -p "Enter the record number you want to update: " record_number
    if validate_number "$record_number"; then
      break
    else
      echo "Invalid input. Please enter a valid record number."
    fi
  done

  selected_record=$(echo "$dns_response" | jq -c ".result[$((record_number - 1))]") # Corrected array indexing
  cf_record_id=$(echo $selected_record | jq -r '.id')
  cf_record_name=$(echo $selected_record | jq -r '.name')
else
  echo "Failed to fetch DNS records or no DNS records found. Exiting."
  exit 1
fi

# Ask the user if they want to use Cloudflare's proxy BEFORE creating the update_dns.sh script
read -p "Do you want to use Cloudflare's proxy (yes or no)? " cf_proxy_choice
case "$cf_proxy_choice" in
  [yY]|[yY][eE][sS])
    cf_proxy_setting=true
    ;;
  *)
    cf_proxy_setting=false
    ;;
esac

# Create the update_dns.sh script
update_dns_path="/usr/local/bin/update_dns.sh"
cat <<EOL > $update_dns_path
#!/bin/bash

# Cloudflare API settings
cf_api_key="$cf_api_key_or_token"
cf_zone_id="$cf_zone_id"
cf_record_id="$cf_record_id"
cf_record_name="$cf_record_name"
$(if [ "$api_type" = "k" ]; then echo "cf_email=\"$cf_email\""; fi)

# Enable or disable debugging
debug=true  # Set to "true" to enable debugging

# Debugging function
debug_msg() {
  if [ "\$debug" = "true" ]; then
    echo "DEBUG: \$1"  # Print the debugging message
  fi
}

# Get the current public IP address
debug_msg "Getting the current public IP address..."
current_ip=\$(curl -s https://api64.ipify.org?format=json | jq -r .ip)

update_dns_record() {
  if [ "$api_type" = "t" ]; then
    curl --request PUT \
      --url "https://api.cloudflare.com/client/v4/zones/\${cf_zone_id}/dns_records/\${cf_record_id}" \
      --header 'Content-Type: application/json' \
      --header "Authorization: Bearer \${cf_api_key}" \
      --data "{
        \"type\": \"A\",
        \"name\": \"\${cf_record_name}\",
        \"content\": \"\${current_ip}\",
        \"proxied\": $cf_proxy_setting,
        \"ttl\": 3600
      }"
  else
    curl --request PUT \
      --url "https://api.cloudflare.com/client/v4/zones/\${cf_zone_id}/dns_records/\${cf_record_id}" \
      --header 'Content-Type: application/json' \
      --header "X-Auth-Email: \${cf_email}" \
      --header "X-Auth-Key: \${cf_api_key}" \
      --data "{
        \"type\": \"A\",
        \"name\": \"\${cf_record_name}\",
        \"content\": \"\${current_ip}\",
        \"proxied\": $cf_proxy_setting,
        \"ttl\": 3600
      }"
  fi

  if [ -n \"\${current_ip}\" ]; then
    echo "DNS record updated successfully."
  else
    echo "Failed to obtain the current IP address."
  fi
}

# Call the update_dns_record function
update_dns_record

EOL

# Make the script executable
chmod +x $update_dns_path

echo "The script 'update_dns.sh' has been created at $update_dns_path and is now executable."

# Execute the created script
$update_dns_path

# Ask the user how often they'd like to have IP updates set to Cloudflare
while :; do
  read -p "How often (in minutes) would you like to have IP updates set to Cloudflare? (e.g., 10, 15, 30) " update_frequency
  if [[ $update_frequency =~ ^[0-9]+$ ]] && (( update_frequency >= 1 )); then
    break
  else
    echo "Invalid input. Please enter a valid number of minutes."
  fi
done

# Check if the cronjob entry for update_dns.sh already exists
cron_entry_exists=$(crontab -l 2>/dev/null | grep -F "$update_dns_path")

if [ -z "$cron_entry_exists" ]; then
  # Add the cronjob
  (crontab -l 2>/dev/null; echo "*/$update_frequency * * * * $update_dns_path > /dev/null 2>&1") | crontab -
  echo "Cronjob has been set to run every $update_frequency minutes."

else
  # Update the existing cronjob
  (crontab -l 2>/dev/null | grep -v "$update_dns_path"; echo "*/$update_frequency * * * * $update_dns_path > /dev/null 2>&1") | crontab -
  echo "Updated cronjob to run every $update_frequency minutes."
fi