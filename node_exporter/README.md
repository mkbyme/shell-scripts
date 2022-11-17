# Cài đặt dịch vụ node_exporter

Môi trường: CentOS/Ubuntu
Yêu cầu: Mạng mở thông tới github.com

## Hướng dẫn cài đặt

Chạy file `install_nodeexporter.sh` để cài đặt

```sh
sudo bash install_nodeexporter.sh
```
Sau đó mở trình duyệt tại đường dẫn http://hostname:9100/metrics để kiểm tra dịch vụ đã hoạt động chưa

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
VERSION=1.4.0; #nhập thông tin phiên bản tại đây
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


