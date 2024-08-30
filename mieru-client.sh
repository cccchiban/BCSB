#!/bin/bash

# Function to prompt user for input
prompt() {
    local prompt_text="$1"
    local default_value="$2"
    read -p "$prompt_text [$default_value]: " input
    echo "${input:-$default_value}"
}

# Function to download and install mieru client
install_mieru() {
    echo "Downloading mieru client..."
    local url="https://github.com/enfein/mieru/releases/download/v3.3.2/mieru_3.3.2_amd64.deb"
    wget "$url" -O mieru.deb

    echo "Installing mieru client..."
    sudo dpkg -i mieru.deb
    sudo apt-get install -f  # Fix any dependency issues
    rm mieru.deb
    echo "mieru client installed successfully."
}

# Function to create configuration file
create_config() {
    local config_file="client_config.json"

    echo "Creating configuration file..."

    local profile_name=$(prompt "Enter profile name" "default")
    local user_name=$(prompt "Enter username" "ducaiguozei")
    local password=$(prompt "Enter password" "xijinping")
    local ip_address=$(prompt "Enter server IP address" "12.34.56.78")
    local domain_name=$(prompt "Enter server domain name (leave blank if none)" "")
    local port=$(prompt "Enter port (e.g., 2027)" "2027")
    local mtu=$(prompt "Enter MTU value (1280-1500)" "1400")
    local multiplexing_level=$(prompt "Enter multiplexing level (MULTIPLEXING_OFF, MULTIPLEXING_LOW, MULTIPLEXING_MIDDLE, MULTIPLEXING_HIGH)" "MULTIPLEXING_LOW")
    local rpc_port=$(prompt "Enter RPC port (1025-65535)" "8964")
    local socks5_port=$(prompt "Enter SOCKS5 port (1025-65535)" "1080")
    local socks5_listen_lan=$(prompt "Allow SOCKS5 listen LAN (true/false)" "false")
    local http_proxy_port=$(prompt "Enter HTTP proxy port (leave blank if not needed)" "")
    local http_proxy_listen_lan=$(prompt "Allow HTTP proxy listen LAN (true/false, leave blank if not needed)" "")

    cat > $config_file <<EOL
{
    "profiles": [
        {
            "profileName": "$profile_name",
            "user": {
                "name": "$user_name",
                "password": "$password"
            },
            "servers": [
                {
                    "ipAddress": "$ip_address",
                    "domainName": "$domain_name",
                    "portBindings": [
                        {
                            "port": $port,
                            "protocol": "TCP"
                        }
                    ]
                }
            ],
            "mtu": $mtu,
            "multiplexing": {
                "level": "$multiplexing_level"
            }
        }
    ],
    "activeProfile": "$profile_name",
    "rpcPort": $rpc_port,
    "socks5Port": $socks5_port,
    "loggingLevel": "INFO",
    "socks5ListenLAN": $socks5_listen_lan
EOL

    if [ -n "$http_proxy_port" ]; then
        cat >> $config_file <<EOL
    ,
    "httpProxyPort": $http_proxy_port,
    "httpProxyListenLAN": $http_proxy_listen_lan
EOL
    fi

    # Close the JSON object
    echo "}" >> $config_file

    echo "Configuration file created successfully."
}

# Function to apply configuration
apply_config() {
    local config_file="client_config.json"
    echo "Applying configuration..."
    mieru apply config $config_file
    if [ $? -ne 0 ]; then
        echo "Failed to apply configuration. Please check the config file and try again."
        exit 1
    fi
    echo "Configuration applied successfully."
}

# Function to start mieru client
start_client() {
    echo "Starting mieru client..."
    mieru start
    if [ $? -ne 0 ]; then
        echo "Failed to start mieru client. Please check the logs for more details."
        exit 1
    fi
    echo "mieru client started successfully."
}

# Function to test connection
test_connection() {
    local test_url=$(prompt "Enter the URL to test connection (leave blank for default test)" "")
    if [ -n "$test_url" ]; then
        mieru test $test_url
    else
        mieru test
    fi
    if [ $? -ne 0 ]; then
        echo "Connection test failed. Please check your configuration and try again."
        exit 1
    fi
    echo "Connection test succeeded."
}

# Main script execution
install_mieru
create_config
apply_config
start_client
test_connection

echo "mieru client setup completed successfully."
