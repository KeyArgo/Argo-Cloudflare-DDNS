# Cloudflare DDNS Client

Automate the updating of a DNS record on Cloudflare with your machine's current public IP. This script serves as a custom DDNS client for Cloudflare.

![Cloudflare Logo](https://www.cloudflare.com/img/cf-facebook-card.png)

## Table of Contents

* [Prerequisites](#prerequisites)
* [Getting Started](#getting-started)
* [Installation](#installation)
* [Usage](#usage)
* [Features](#features)
* [Contributing](#contributing)
* [License](#license)

## Prerequisites

* The script requires `sudo` privileges to execute.
* [`jq`](https://stedolan.github.io/jq/) needs to be installed. It's a lightweight and flexible command-line JSON processor.

## Getting Started

Before using the script, ensure you have the following from Cloudflare:

1. **API Token or API Key**:
    
    * To generate an API Token, visit the [API Tokens](https://dash.cloudflare.com/profile/api-tokens) page in your Cloudflare dashboard. Create a token with permissions to edit DNS records.
    * If using an API Key, navigate to the [API Tokens](https://dash.cloudflare.com/profile/api-tokens) page, and your Global API Key will be available there. Do note that using the API Key is less secure than a scoped API Token.
2. **Zone ID**:
    
    * This can be found in the Cloudflare dashboard for your domain. Navigate to the overview page, and the Zone ID will be listed in the right sidebar.
3. **A Record Setup**:
    
    * Ensure you have an 'A' record set up on Cloudflare. Note down the record ID and name, as you will need these during the script's execution.

## Installation

1. Clone this repository:
    
    ```bash
    git clone https://github.com/KeyArgo/Cloudflare_DDNS_Client.git
    ```
    
2. Navigate to the cloned directory:
    
    ```bash
    cd Cloudflare_DDNS_Client
    ```
    

## Usage

1. Run the script:
    
    ```bash
    sudo ./cloudflare_ddns_client.sh
    ```
    
2. Follow the on-screen prompts. You'll be asked to:
    * Enter your Cloudflare API Token or API Key.
    * Specify if you're using an API Token or API Key.
    * Provide your Cloudflare Email Address (only if using an API Key).
    * Input your Cloudflare Zone ID.
    * Choose the DNS record you want to update.
    * Decide on using Cloudflare's proxy.
    * Define the update frequency for your IP on Cloudflare.

After the initial setup, an `update_dns.sh` script will be generated in `/usr/local/bin/`. This script is responsible for updating the DNS record. A cronjob will also be configured to execute this script at your chosen frequency.

## Features

* **Input Validation**: Ensures valid Cloudflare credentials and DNS record selection.
* **Auto Script Creation**: Generates `update_dns.sh` for DNS record updates.
* **Cron Scheduling**: Regularly updates the DNS record with the machine's current public IP.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)

* * *

This revised README provides a clear guide on the required Cloudflare details and how to obtain them, ensuring users are well-prepared before using the script.
