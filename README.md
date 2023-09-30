# Cloudflare DDNS Client

Automate the updating of a DNS record on Cloudflare with your machine's current public IP. This script acts as a DDNS client tailored for Cloudflare.

![Cloudflare Logo](https://www.cloudflare.com/img/cf-facebook-card.png)

## Table of Contents

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Usage](#usage)
* [Features](#features)
* [Contributing](#contributing)
* [License](#license)

## Prerequisites

* The script requires `sudo` privileges to execute.
* [`jq`](https://stedolan.github.io/jq/) needs to be installed. It's a lightweight and flexible command-line JSON processor.

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

After the initial setup, an `update_dns.sh` script will be generated in `/usr/local/bin/`. This script handles the DNS record updates. Additionally, a cronjob will be configured to execute this script at your chosen frequency.

## Features

* **Input Validation**: Ensures valid Cloudflare credentials and DNS record selection.
* **Auto Script Creation**: Generates `update_dns.sh` for DNS record updates.
* **Cron Scheduling**: Regularly updates the DNS record with the machine's current public IP.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)

* * *

This README is tailored for GitHub, including a logo for visual appeal, a table of contents for easy navigation, and sections that are common for GitHub repositories, such as "Contributing" and "License". Adjust as needed based on your project's specifics!
