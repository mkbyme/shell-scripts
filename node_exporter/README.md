# Bước 1: Cài đặt dịch vụ node_exporter

## Cài đặt online

Môi trường: CentOS/Ubuntu
Yêu cầu: Mạng mở thông tới github.com

```sh
# tải file
curl -O https://raw.githubusercontent.com/mkbyme/shell-scripts/main/node_exporter/install_nodeexporter.sh
sudo bash install_nodeexporter.sh
```

Chạy file `install_nodeexporter.sh` để cài đặt

Sau đó mở trình duyệt tại đường dẫn http://hostname:9100/metrics để kiểm tra dịch vụ đã hoạt động chưa

## Cài đặt offline

Cài đặt offline tải releases v1.0.1 [tại đây](https://github.com/mkbyme/shell-scripts/releases/download/node_exporter_v1.0.1/node_exporter_v1.0.1.zip)

Với cài đặt offline thì sau khi tài file zip trên, copy lên máy chủ và giải nén sử dụng script dưới đây.

```sh
# di chuyển về thư mục home
cd ~
# tạo thư mục temp, và copy file zip qua winscp
mkdir -p temp
# di chuyển vào thư mục chứa file zip, unzip
cd temp
# giải nén
unzip node_exporter_v1.0.1.zip
# di chuyển vào thư mục vừa giải nén và chạy file 
sudo bash install_nodeexporter.sh
# trường hợp cần cài đặt ở cổng khác hoặc version khác sử dụng thêm tham số --port=[cổng, vd: 10100] --version=[phiên bản, vd: 1.5.0]
# sudo bash install_nodeexporter.sh --port 10100
```

Sau đó mở trình duyệt tại đường dẫn http://hostname:9100/metrics để kiểm tra dịch vụ đã hoạt động chưa

## Hướng dẫn cài đặt hàng loạt qua anisible

Sử dụng file playbook tại [anisible.yaml](/node_exporter/anisible.yml)

Hoặc copy nội dung bên dưới

```yaml
tasks:
  - name: Transfer script
    copy: src=/tmp/script_setup_nodeexporter/install_nodeexporter.sh dest=/tmp/node_exporter mode=0755

  - name: Transfer file
    copy: src=/tmp/script_setup_nodeexporter/node_exporter-1.4.0.linux-amd64.tar.gz dest=/tmp/node_exporter

  - name: Run script
    command: sudo bash /tmp/node_exporter/install_nodeexporter.sh

  - name: Delete script
    command: rm -rf /tmp/node_exporter

  - name: Check and start service
    command: sudo systemctl start node_exporter
```

Sau đó sử dụng anisible để chạy playbook trên.

## Gỡ bỏ dịch vụ

Chạy file `install_nodeexporter.sh` để cài đặt

```sh
sudo bash uninstall_nodeexporter.sh
```

## Cập nhật phiên bản

Để cập nhật dịch vụ cần thực hiện cập nhật phiên bản trong file `install_nodeexporter.sh`

Tìm phiên bản node_exporter tại: https://github.com/prometheus/node_exporter/tags

Ví dụ: **1.4.0**

```sh
#!/bin/bash
VERSION=1.4.0; #nhập thông tin phiên bản tại đây hoặc qua param --version 1.4.0
FILENAME=node_exporter-${VERSION}.linux-amd64.tar.gz;
```

Sau khi sửa xong lưu lại và chạy lệnh bên dưới để cập nhật

```sh
#gỡ phiên bản cũ
sudo bash uninstall_nodeexporter.sh
#cài lại bản mới
sudo bash install_nodeexporter.sh
```

Done

# Bước 2: Cấu hình scrape từ prometheus

## Sử dụng chart database-resource

Copy file cấu hình trong `monitor/shared/template/database-resource-monitor-value.yaml`

Mở file ra và sửa các thông tin

- `configs.group`: tên khối dự án
- `configs.dbType`: loại db mysql|postgresql|mongo
- `services`: nhập danh sách tên máy chủ và ip, port dịch vụ node_exporter (mặc định 9100)

Ví dụ

```yaml
configs:
  #port mac dinh cho dich vu node_exporter
  port: 9100 
  # EDIT01: khoi du an
  group: "doanhnghiep"
  # EDIT02: loai db mysql|postgresql|mongo
  dbType: "mysql" #mysql|postgresql|mongo
  serviceAdditionalsLabels: []
  
# EDIT03: danh sach hostname va ip, port toi dich vu node_exporter database
services:
  doanhnghiep-mysql-01:
    ip: 192.168.100.1
    # port: 9200 #ghi de lai port trong configs.port neu dich vu o port khac  
  doanhnghiep-mysql-02:
    ip: 192.168.100.2
```

Sau đó cài đặt chart với values trên.

```sh
# helm -n [namespace dự án] [tên reslease] /monitor/shared/template/database-resources-monitor -f  atabase-resource-monitor-value.yaml
helm -n demo doanhnghiep-mysql monitor/shared/template/database-resources-monitor -f  atabase-resource-monitor-value.yaml
```

Kiểm tra xem dịch vụ đã thông chưa

```sh
# tìm service vừa cài đặt, lấy thông tin ClusterIp
kubeclt -n demo get svc | grep doanhnghiep-mysql 
# curl ip:port # của dịch vụ exporter trên, nếu ra dữ liệu up = 1 là ok
curl 10.0.1.43:9100/metrics | grep up
```

Kiểm tra hiển thị trên databoard của team DBE

# Hướng dẫn kiểm tra trạng thái và xử lý cảnh báo TargetDown

Khi dịch vụ ngừng sẽ nhận được cảnh báo `TargetDown`, kiểm tra dịch vụ qua trình duyệt hoặc curl tới ip_node_cai_dat_exporter:9100

Ví dụ: Remote vào node cần kiểm tra `demo-node-01`

```sh
# gọi qua curl, nếu trả về dữ liệu là sống, không trả về là chết
curl 0.0.0.0:9100
```

```sh
#kiểm tra trạng thái
systemctl status node_exporter
# nếu stop thì thực hiện start lên hoặc restart
systemctl start node_exporter
```
