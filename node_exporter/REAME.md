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
