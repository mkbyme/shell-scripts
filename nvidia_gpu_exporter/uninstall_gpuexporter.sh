#!/bin/bash

# Default parameters
DEFAULT_PORT=9835
FALLBACK_PORT=19835
PORT=$DEFAULT_PORT
gpu_exporter_binary=/usr/local/bin/nvidia-gpu-exporter
daemon_service_path=/etc/systemd/system/nvidia-gpu-exporter.service
username=gpuusr

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --port <port>        Specify the port used by nvidia-gpu-exporter (default: $DEFAULT_PORT, also checks $FALLBACK_PORT if no port specified)"
    echo "Example: $0 --port 9835"
    if [[ -z "$1" ]]; then
        exit 1
    fi
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --port) PORT="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

if [[ "$PORT" != "$DEFAULT_PORT" ]]; then
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo "Error: Invalid port number. Please specify a port between 1 and 65535."
        exit 1
    fi
fi

echo "Supported CLI parameters:"
usage 0

echo "-----------Remove NVIDIA GPU Exporter-----------"
if [[ -e "$daemon_service_path" ]]; then
    echo "[Service]: Stopping service"
    sudo systemctl stop nvidia-gpu-exporter.service
    echo "[Service]: Disabling service"
    sudo systemctl disable nvidia-gpu-exporter
    echo "[Service]: Removing daemon service config at '$daemon_service_path'"
    sudo rm "$daemon_service_path"
    echo "[Service]: Reloading daemon"
    sudo systemctl daemon-reload
else
    echo "[Service]: nvidia-gpu-exporter service not found on system, skipping!"
fi
echo "------------"
if [[ -e "$gpu_exporter_binary" ]]; then
    echo "[File]: Removing nvidia-gpu-exporter binary at '$gpu_exporter_binary'"
    sudo rm "$gpu_exporter_binary"
else
    echo "[File]: Binary '$gpu_exporter_binary' not found, skipping!"
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
            echo "[Firewall]: Removing rule for nvidia-gpu-exporter port $port"
            sudo ufw delete allow $port
        else
            echo "[Firewall]: No rule found for nvidia-gpu-exporter port $port, skipping"
        fi
    done
else 
    echo "[Firewall]: Using iptables"
    for port in "${ports_to_check[@]}"; do
        firewall_rule=$(sudo iptables -L INPUT -n --line-numbers | grep "$port.*nvidia-gpu-exporter")
        if [[ -z "${firewall_rule}" ]]; then
            echo "[Firewall]: No rule found for nvidia-gpu-exporter port $port, skipping"
        else
            rule_number=$(echo "$firewall_rule" | awk '{print $1}')
            echo "[Firewall]: Removing rule for nvidia-gpu-exporter port $port"
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
echo "-----------Remove NVIDIA GPU Exporter Complete-----------"
