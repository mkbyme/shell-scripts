#!/bin/bash
VERSION=1.4.0;
FILENAME=node_exporter-${VERSION}.linux-amd64.tar.gz;
URL=https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${FILENAME};

download_file(){
    node_exporter_binary="$(pwd)/node_exporter-${VERSION}.linux-amd64/node_exporter";
    echo "--------------Download Binary-----------"
    if [[ -e /usr/local/bin/node_exporter ]]; then 
        echo "[Download]: Da co dich node_exporter tren may tai /usr/local/bin/node_exporter , khong thuc hien cai dat tiep."; 
    else 
        if [[ -e "$FILENAME" ]]; then
            echo "[Download]: Da ton tai file zip local, copy ngay";
        else
            echo "[Download]: Tai node_exporter phien ban ${VERSION}"
            wget $URL;
            echo "[Download]: Tai xong!"
        fi
        echo "[Download]: Giai nen node_exporter phien ban ${VERSION}"
        tar -xzvf $FILENAME;
        echo "[Download]: Gia- nen xong!"
        echo "[Download]: Copy file vao /usr/local/bin/"
        sudo cp "$node_exporter_binary" /usr/local/bin/
        echo "[Download]: Copy file vao /usr/local/bin/ xong!"
        echo "[Download]: Don dep file giai nen"
        sudo rm -rf "$(pwd)/node_exporter-${VERSION}.linux-amd64"
        echo "[Download]: Don dep file giai nen, xong!"
    fi

}

create_daemon_service(){
    #tao user
    echo "--------------Create User-----------"
    username="nodeusr"
    exists_user=$(cat /etc/passwd | grep ${username});
    if [[ -z "${exists_user}" ]]; then
        echo "[User]: Tao user '${username}'";
        sudo useradd -rs /bin/false $username;
    else
        echo "[User]: User '${username}' da ton tai, khong thuc hien tao user";
    fi;

    #tao daeomon-service
    echo "--------------Create Daemon Service-----------"

    service_file="/etc/systemd/system/node_exporter.service"
    if [[ -e "${service_file}" ]]; then 
        echo "[Daemon]: File daemon ${service_file} da ton tai, bo qua viec khoi tao file";
    else
        echo "[Daemon]: File daemon ${service_file} chua ton tai, thuc hien tao file va setup daemon.";
        sudo cat <<EOF > "$service_file"
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=$username
Group=$username
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
        echo "[Daemon]: Reload daemon";
        sudo systemctl daemon-reload;
        echo "[Daemon]: Mo dich vu node-exporter khoi chay cung he thong";
        sudo systemctl enable node_exporter;
        echo "[Daemon]: Khoi chay dich vu";
        sleep 3
        sudo systemctl start node_exporter;
    fi

    # add rule firewall
    # check iptables or ufw
    echo "--------------Add Firewall-----------"
    if command -v ufw &> /dev/null && [[ -n "$(sudo ufw status | grep ': active')" ]]; then 
        #co ufw va duoc bat status: active thi moi su dung ufw
        echo "[Firewall]: using UFW";
        if [[ -z "$(sudo ufw status | grep 9100)" ]]; then
            echo "[Firewall]: chua mo port 9100, thuc hien add rule 9100";
            sudo ufw allow 9100
        else
            echo "[Firewall]: da mo port 9100";
        fi
    else 
        echo "[Firewall]: using iptables";
        firewall_rule=$(sudo iptables -L INPUT | grep node_exporter);
        if [[ -z "${firewall_rule}" ]]; then
            echo "[Firewall]: chua mo port 9100, thuc hien add rule 9100";
            sudo iptables -I INPUT 1 -p tcp --dport 9100 -j ACCEPT -m comment --comment "node_exporter";
        else
            echo "[Firewall]: da mo port 9100";
        fi
    fi    
}

run(){
    echo "-----------SETUP NODE EXPORTER ${VERSION}------------"
    echo "[Setup]: Kiem tra va cai dat node_exporter:${VERSION}"
    download_file;
    create_daemon_service;
    echo "-----------------------"
    echo "[Setup]: da cai dat xong"; 
    echo "-----------------------"
    echo "[Setup]: Kiem tra dich vu tai http://$(hostname):9100/metrics";
}
run;
