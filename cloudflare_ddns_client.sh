#!/bin/bash

# Function to validate user input for record number
validate_number() {
  local num=$1
  [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= index - 1 ))
}

# Ask the user for Cloudflare API Token/Key, Email (if API Key is used), and Zone ID
read -p "Enter your Cloudflare API Token/Key: " cf_api_key_or_token
read -p "Are you using API Token (t) or API Key (k)? " api_type
if [ "$api_type" = "k" ]; then
  read -p "Enter your Cloudflare Email Address: " cf_email
fi
read -p "Enter your Cloudflare Zone ID: " cf_zone_id

# Verify the provided API Token/Key
if [ "$api_type" = "t" ]; then
  verify_response=$(curl --silent --request GET \
    --url "https://api.cloudflare.com/client/v4/user/tokens/verify" \
    --header "Authorization: Bearer ${cf_api_key_or_token}" \
    --header "Content-Type: application/json")
else
  verify_response=$(curl --silent --request GET \
    --url "https://api.cloudflare.com/client/v4/zones/${cf_zone_id}/dns_records" \
    --header "X-Auth-Email: ${cf_email}" \
    --header "X-Auth-Key: ${cf_api_key_or_token}" \
    --header "Content-Type: application/json")
fi

if echo "$verify_response" | jq -e '.success == true' >/dev/null; then
  echo "API Key/Token verification successful!"
else
  echo "API Key/Token verification failed. Exiting."
  exit 1
fi

# Fetch DNS records
dns_response=$(curl --silent --request GET \
  --url "https://api.cloudflare.com/client/v4/zones/${cf_zone_id}/dns_records" \
  --header "Authorization: Bearer ${cf_api_key_or_token}" \
  --header "Content-Type: application/json")

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

# Update the DNS record with the new IP address
debug_msg "Updating DNS record with new IP address..."
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
        \"proxied\": true,
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
        \"proxied\": true,
        \"ttl\": 3600
      }"
  fi
}

if [ -n "\$current_ip" ]; then
  update_dns_record
  echo "DNS record updated successfully."
else
  echo "Failed to obtain the current IP address."
fi

EOL

# Make the script executable
chmod +x $update_dns_path

echo "The script 'update_dns.sh' has been created at $update_dns_path and is now executable."

# Execute the created script
$update_dns_path

# Ask the user for the update frequency with a default value of every hour
read -p "Enter the update frequency in minutes (default is 60): " update_frequency
# If the user input is empty, set the default value
update_frequency=${update_frequency:-60}
# Calculate the frequency in cron expression
cron_expression="*/$update_frequency * * * *"

# Add a cron job to execute the script at the specified interval
(crontab -l 2>/dev/null; echo "$cron_expression /usr/local/bin/update_dns.sh") | crontab -

echo "A cron job has been added to execute /usr/local/bin/update_dns.sh every $update_frequency minutes."
