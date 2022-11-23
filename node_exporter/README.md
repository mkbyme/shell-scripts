# Bước 1: Cài đặt dịch vụ node_exporter

## Cài đặt online

Môi trường: CentOS/Ubuntu
Yêu cầu: Mạng mở thông tới github.com

## Cài đặt offline

Cài đặt offline tải releases v1.0.0 [tại đây](https://github.com/mkbyme/shell-scripts/releases/download/node_exporter_v1.0.0/node_exporterscript_setup_nodeexporter_v1.0.0.zip)

## Hướng dẫn cài đặt

Với cài đặt offline thì sau khi tài file zip trên, copy lên máy chủ và giải nén

```sh
# di chuyển về thư mục home
cd ~
# tạo thư mục temp, và copy file zip qua winscp
mkdir -p temp
# di chuyển vào thư mục chứa file zip, unzip
cd temp
# giải nén
unzip node_exporterscript_setup_nodeexporter_v1.0.0.zip
# di chuyển vào thư mục vừa giải nén và chạy file 
sudo bash install_nodeexporter.sh
```

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

# Bước 2: Cấu hình scrape từ prometheus

Để có thể lấy được metrics node cần bổ sung cấu hình trên file `additional-scrape-configs.yaml` trong `monitor/shared`

Với nội dung như sau, tìm tới đoạn của dự án
Ví dụ **meinvoice**, sau đó nối tiếp config vào phần của dự án

Yêu cầu:

**`job_name`**: đặt theo tiêu chuẩn `database/node-exporter-[mã dự án]-[tên host name của máy chủ database]`

Ví dụ: hostname=inv-db-12, mã dự án=meinvoice => database/node-exporter-meinvoice-inv-db-12

**`labels`**: phải có nhãn `db` với các giá trị sau
- `mysql`: Dùng cho loại database là mysql
- `postgresql`: Dùng cho loại database là postgresql

**`namespace`**: Đặt trùng với namespace dự án trên K8SMonitor, ví dụ `meinvoice`

File ví dụ như bên dưới:

```yaml

    - job_name: database/node-exporter-meinvoice-inv-db-12 # phải đặt tên tiền tố là database
      static_configs:
      - labels:
          hostname: inv-db-12
          namespace: meinvoice
          db: mysql #chỉ định nhãn là mysql,postgresql
        targets:
        - inv-db-12:9100

```

Sau khi sửa xong file trên thực hiện apply file
```sh
k apply -f  additional-scrape-configs.yaml
```

Kiểm tra hiển thị trên databoard của team DBE

