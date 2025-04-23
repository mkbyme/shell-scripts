#!/bin/bash

# Default parameters
DEFAULT_PORT=9100
FALLBACK_PORT=10100
PORT=$DEFAULT_PORT
DEFAULT_VERSION=1.4.0
VERSION=$DEFAULT_VERSION

# Usage function to display supported CLI parameters
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --port <port>        Specify the port for node_exporter (default: $DEFAULT_PORT, fallback: $FALLBACK_PORT if $DEFAULT_PORT is in use)"
    echo "  --version <version>  Specify the version of node_exporter (default: $DEFAULT_VERSION)"
    echo "Example: $0 --port 9100 --version 1.4.0"
    
    if [[ -z "$1" ]]; then
        exit 1
    fi
}

# Function to check if a port is in use
check_port() {
    local port=$1
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -q ":${port}\b" && return 0
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":${port}\b" && return 0
    fi
    return 1
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --port) PORT="$2"; shift ;;
        --version) VERSION="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# If no port specified, check if default port is in use and switch to fallback if needed
if [[ "$PORT" == "$DEFAULT_PORT" ]]; then
    if check_port "$DEFAULT_PORT"; then
        echo "[Port]: Default port $DEFAULT_PORT is in use, switching to fallback port $FALLBACK_PORT"
        PORT=$FALLBACK_PORT
        if check_port "$FALLBACK_PORT"; then
            echo "Error: Fallback port $FALLBACK_PORT is also in use. Please specify a free port using --port."
            exit 1
        fi
    fi
fi

# Validate port number
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "Error: Invalid port number. Please specify a port between 1 and 65535."
    exit 1
fi

# Validate version format (basic validation for x.y.z format)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Please specify version in x.y.z format (e.g., 1.4.0)."
    exit 1
fi

FILENAME=node_exporter-${VERSION}.linux-amd64.tar.gz
URL=https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${FILENAME}

download_file(){
    script_folder_path=$( dirname -- "$0" )
    node_exporter_folder="$script_folder_path/node_exporter-${VERSION}.linux-amd64"
    node_exporter_binary="$node_exporter_folder/node_exporter"
    file_path=$script_folder_path/$FILENAME
    echo "--------------Download Binary-----------"
    if [[ -e /usr/local/bin/node_exporter ]]; then 
        echo "[Download]: Node_exporter already exists at /usr/local/bin/node_exporter, skipping installation."
    else 
        if [[ -e "$file_path" ]]; then
            echo "[Download]: Local zip file already exists, copying directly"
        else
            echo "[Download]: Downloading node_exporter version ${VERSION}"
            wget $URL --directory-prefix "$script_folder_path/"
            echo "[Download]: Download complete!"
        fi
        echo "[Download]: Extracting node_exporter version ${VERSION} to '$script_folder_path'"
        tar -xzvf $file_path --directory $script_folder_path
        echo "[Download]: Extraction complete!"
        echo "[Download]: Copying '$node_exporter_binary' to '/usr/local/bin/'"
        sudo cp "$node_exporter_binary" /usr/local/bin/
        echo "[Download]: Copy complete!"
        echo "[Download]: Cleaning up extracted files at '$node_exporter_folder'"
        sudo rm -rf "$node_exporter_folder"
        echo "[Download]: Cleanup complete!"
    fi
}

create_daemon_service(){
    echo "--------------Create User-----------"
    username="nodeusr"
    exists_user=$(cat /etc/passwd | grep ${username})
    if [[ -z "${exists_user}" ]]; then
        echo "[User]: Creating user '${username}'"
        sudo useradd -rs /bin/false $username
    else
        echo "[User]: User '${username}' already exists, skipping user creation"
    fi

    echo "--------------Create Daemon Service-----------"
    service_file="/etc/systemd/system/node_exporter.service"
    if [[ -e "${service_file}" ]]; then 
        echo "[Daemon]: Daemon file ${service_file} already exists, skipping creation"
    else
        echo "[Daemon]: Daemon file ${service_file} does not exist, creating and setting up daemon"
        sudo cat <<EOF > "$service_file"
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=$username
Group=$username
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:${PORT}

[Install]
WantedBy=multi-user.target
EOF
        echo "[Daemon]: Reloading daemon"
        sudo systemctl daemon-reload
        echo "[Daemon]: Enabling node-exporter to start on boot"
        sudo systemctl enable node_exporter
        echo "[Daemon]: Starting service"
        sleep 3
        sudo systemctl start node_exporter
    fi

    echo "--------------Add Firewall-----------"
    if command -v ufw &> /dev/null && [[ -n "$(sudo ufw status | grep ': active')" ]]; then 
        echo "[Firewall]: Using UFW"
        if [[ -z "$(sudo ufw status | grep $PORT)" ]]; then
            echo "[Firewall]: Port $PORT not open, adding rule"
            sudo ufw allow $PORT
        else
            echo "[Firewall]: Port $PORT already open"
        fi
    else 
        echo "[Firewall]: Using iptables"
        firewall_rule=$(sudo iptables -L INPUT | grep node_exporter)
        if [[ -z "${firewall_rule}" ]]; then
            echo "[Firewall]: Port $PORT not open, adding rule"
            sudo iptables -I INPUT 1 -p tcp --dport $PORT -j ACCEPT -m comment --comment "node_exporter"
        else
            echo "[Firewall]: Port $PORT already open"
        fi

        echo "[Firewall]: Saving rules"
        sudo service iptables save
        echo "[Firewall]: Reloading rules"
        sudo service iptables reload
    fi    
}

run(){
    echo "-----------SETUP NODE EXPORTER ${VERSION}------------"
    echo "[Setup]: Checking and installing node_exporter:${VERSION} on port ${PORT}"
    download_file
    create_daemon_service
    echo "-----------------------"
    echo "[Setup]: Installation complete"
    echo "-----------------------"
    echo "[Setup]: Check service at http://$(hostname):${PORT}/metrics"
}

# Display usage information before running
echo "Supported CLI parameters:"
usage 0
run