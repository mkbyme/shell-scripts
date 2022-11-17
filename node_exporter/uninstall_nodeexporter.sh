#!/bin/bash
node_exporter_binary=/usr/local/bin/node_exporter
daemon_service_path=/etc/systemd/system/node_exporter.service
username=nodeusr
#--------
echo "-----------Remove NodeExporter-----------"
if [[ -e "$daemon_service_path" ]]; then
    echo "[Service]: top service"
    systemctl stop node_exporter.service
    echo "[Service]: Disable service"
    sudo systemctl disable node_exporter;
    echo "[Service]: Remove deamon service config tai '$daemon_service_path'"
    sudo rm $daemon_service_path
    echo "[Service]: Reload deamon"
    sudo systemctl daemon-reload;
else
    echo "[Service]: Service node_exporter khong co tren may, bo qua!"
fi
echo "------------"
if [[ -e "$node_exporter_binary" ]]; then
    echo "[File]: Remove node_exporter binary tai '$node_exporter_binary'"
    sudo rm $node_exporter_binary
else
    echo "[File]: Binary '$node_exporter_binary' khong ton tai, bo qua!"
fi
echo "------------"
#firewall rule
echo "[Firewall]: Remove firewal rule"
if command -v ufw &> /dev/null && [[ -n "$(sudo ufw status | grep ': active')" ]]; then 
    #co ufw va duoc bat status: active thi moi su dung ufw
    echo "[Firewall]: using UFW";
    if [[ -n "$(sudo ufw status | grep 9100)" ]]; then
        echo "[Firewall]: Da xoa bo rule node_exporter 9100";
        sudo ufw delete allow 9100
    else
        echo "[Firewall]: Khong co rule node_exporter 9100, bo qua";
    fi
else 
    echo "[Firewall]: using iptables";
    firewall_rule=$(sudo iptables -L INPUT | grep node_exporter);
    if [[ -z "${firewall_rule}" ]]; then
        echo "[Firewall]: Khong co rule node_exporter 9100, bo qua";
    else
        sudo iptables -D INPUT -p tcp --dport 9100 -j ACCEPT -m comment --comment "node_exporter";
        echo "[Firewall]: Da xoa bo rule node_exporter 9100";
    fi
fi
echo "------------"
#remove user
echo "[User]: Delete User $username"
sudo userdel $username
echo "-----------Remove NodeExporter-----------"