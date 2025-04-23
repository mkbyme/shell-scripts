#!/bin/bash

# Default parameters
DEFAULT_PORT=9100
FALLBACK_PORT=10100
PORT=$DEFAULT_PORT
node_exporter_binary=/usr/local/bin/node_exporter
daemon_service_path=/etc/systemd/system/node_exporter.service
username=nodeusr

# Usage function to display supported CLI parameters
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --port <port>        Specify the port used by node_exporter (default: $DEFAULT_PORT, also checks $FALLBACK_PORT if no port specified)"
    echo "Example: $0 --port 9101"
    
    if [[ -z "$1" ]]; then
        exit 1
    fi
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --port) PORT="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# Validate port number if specified
if [[ "$PORT" != "$DEFAULT_PORT" ]]; then
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo "Error: Invalid port number. Please specify a port between 1 and 65535."
        exit 1
    fi
fi

# Display usage information before running
echo "Supported CLI parameters:"
usage 0

echo "-----------Remove NodeExporter-----------"
if [[ -e "$daemon_service_path" ]]; then
    echo "[Service]: Stopping service"
    sudo systemctl stop node_exporter.service
    echo "[Service]: Disabling service"
    sudo systemctl disable node_exporter
    echo "[Service]: Removing daemon service config at '$daemon_service_path'"
    sudo rm "$daemon_service_path"
    echo "[Service]: Reloading daemon"
    sudo systemctl daemon-reload
else
    echo "[Service]: Node_exporter service not found on system, skipping!"
fi
echo "------------"
if [[ -e "$node_exporter_binary" ]]; then
    echo "[File]: Removing node_exporter binary at '$node_exporter_binary'"
    sudo rm "$node_exporter_binary"
else
    echo "[File]: Binary '$node_exporter_binary' not found, skipping!"
fi
echo "------------"
# Firewall rule
echo "[Firewall]: Removing firewall rule(s)"
if [[ "$PORT" == "$DEFAULT_PORT" ]]; then
    ports_to_check=("$DEFAULT_PORT" "$FALLBACK_PORT")
else
    ports_to_check=("$PORT")
fi

if command -v ufw &> /dev/null && [[ -n "$(sudo ufw status | grep ': active')" ]]; then 
    echo "[Firewall]: Using UFW"
    for port in "${ports_to_check[@]}"; do
        if [[ -n "$(sudo ufw status | grep $port)" ]]; then
            echo "[Firewall]: Removing rule for node_exporter port $port"
            sudo ufw delete allow $port
        else
            echo "[Firewall]: No rule found for node_exporter port $port, skipping"
        fi
    done
else 
    echo "[Firewall]: Using iptables"
    for port in "${ports_to_check[@]}"; do
        firewall_rule=$(sudo iptables -L INPUT -n --line-numbers | grep "$port.*node_exporter")
        if [[ -z "${firewall_rule}" ]]; then
            echo "[Firewall]: No rule found for node_exporter port $port, skipping"
        else
            rule_number=$(echo "$firewall_rule" | awk '{print $1}')
            echo "[Firewall]: Removing rule for node_exporter port $port"
            sudo iptables -D INPUT "$rule_number"
            echo "[Firewall]: Saving iptables rules"
            sudo service iptables save
            echo "[Firewall]: Reloading iptables rules"
            sudo service iptables reload
        fi
    done
fi
echo "------------"
# Remove user
echo "[User]: Deleting user $username"
if id "$username" &>/dev/null; then
    sudo userdel "$username"
else
    echo "[User]: User $username does not exist, skipping"
fi
echo "-----------Remove NodeExporter Complete-----------"