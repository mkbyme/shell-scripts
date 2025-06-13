#!/bin/bash

# Default parameters
DEFAULT_PORT=9835
FALLBACK_PORT=19835
PORT=$DEFAULT_PORT
DEFAULT_VERSION=1.3.2
VERSION=$DEFAULT_VERSION

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --port <port>        Specify the port for nvidia_gpu_exporter (default: $DEFAULT_PORT, fallback: $FALLBACK_PORT if $DEFAULT_PORT is in use)"
    echo "  --version <version>  Specify the version of nvidia_gpu_exporter (default: $DEFAULT_VERSION)"
    echo "Example: $0 --port 9835 --version 1.3.2"
    if [[ -z "$1" ]]; then
        exit 1
    fi
}

check_port() {
    local port=$1
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -q ":${port}\b" && return 0
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":${port}\b" && return 0
    fi
    return 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --port) PORT="$2"; shift ;;
        --version) VERSION="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

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

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "Error: Invalid port number. Please specify a port between 1 and 65535."
    exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Please specify version in x.y.z format (e.g., 1.3.2)."
    exit 1
fi

FILENAME=nvidia-gpu-exporter_${VERSION}_linux_amd64.deb
URL=https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v${VERSION}/${FILENAME}

install_exporter() {
    script_folder_path=$( dirname -- "$0" )
    file_path=$script_folder_path/$FILENAME
    echo "--------------Download Binary-----------"
    if [[ -e /usr/local/bin/nvidia-gpu-exporter ]]; then 
        echo "[Download]: nvidia-gpu-exporter already exists at /usr/local/bin/nvidia-gpu-exporter, skipping installation."
    else 
        if [[ -e "$file_path" ]]; then
            echo "[Download]: Local deb file already exists, installing directly"
        else
            echo "[Download]: Downloading nvidia-gpu-exporter version ${VERSION}"
            wget $URL --directory-prefix "$script_folder_path/"
            echo "[Download]: Download complete!"
        fi
        echo "[Download]: Installing nvidia-gpu-exporter version ${VERSION}"
        sudo dpkg -i $file_path
        echo "[Download]: Install complete!"
    fi
}

create_daemon_service() {
    echo "--------------Create User-----------"
    username="gpuusr"
    exists_user=$(cat /etc/passwd | grep ${username})
    if [[ -z "${exists_user}" ]]; then
        echo "[User]: Creating user '${username}'"
        sudo useradd -rs /bin/false $username
    else
        echo "[User]: User '${username}' already exists, skipping user creation"
    fi

    echo "--------------Create Daemon Service-----------"
    service_file="/etc/systemd/system/nvidia-gpu-exporter.service"
    if [[ -e "${service_file}" ]]; then 
        echo "[Daemon]: Daemon file ${service_file} already exists, skipping creation"
    else
        echo "[Daemon]: Daemon file ${service_file} does not exist, creating and setting up daemon"
        sudo cat <<EOF > "$service_file"
[Unit]
Description=NVIDIA GPU Exporter
After=network.target

[Service]
User=$username
Group=$username
Type=simple
ExecStart=/usr/local/bin/nvidia-gpu-exporter --web.listen-address=:$PORT

[Install]
WantedBy=multi-user.target
EOF
        echo "[Daemon]: Reloading daemon"
        sudo systemctl daemon-reload
        echo "[Daemon]: Enabling nvidia-gpu-exporter to start on boot"
        sudo systemctl enable nvidia-gpu-exporter
        echo "[Daemon]: Starting service"
        sleep 3
        sudo systemctl start nvidia-gpu-exporter
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
        firewall_rule=$(sudo iptables -L INPUT | grep nvidia-gpu-exporter)
        if [[ -z "${firewall_rule}" ]]; then
            echo "[Firewall]: Port $PORT not open, adding rule"
            sudo iptables -I INPUT 1 -p tcp --dport $PORT -j ACCEPT -m comment --comment "nvidia-gpu-exporter"
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
    echo "-----------SETUP NVIDIA GPU EXPORTER ${VERSION}------------"
    echo "[Setup]: Checking and installing nvidia-gpu-exporter:${VERSION} on port ${PORT}"
    install_exporter
    create_daemon_service
    echo "-----------------------"
    echo "[Setup]: Installation complete"
    echo "-----------------------"
    echo "[Setup]: Check service at http://$(hostname):${PORT}/metrics"
}

echo "Supported CLI parameters:"
usage 0
run
