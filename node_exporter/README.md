# Bước 1: Cài đặt dịch vụ node_exporter

## Cài đặt online

Môi trường: CentOS/Ubuntu
Yêu cầu: Mạng mở thông tới github.com

## Cài đặt offline

Cài đặt offline tải releases v1.0.1 [tại đây](https://github.com/mkbyme/shell-scripts/releases/download/node_exporter_v1.0.1/node_exporter_v1.0.1.zip)


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
```

Sau đó sử dụng anisible để chạy playbook trên.

## Hướng dẫn cài đặt thủ công

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

Có mạng thì làm như sau:

Chạy file `install_nodeexporter.sh` để cài đặt

```sh
# tải file
curl -O https://raw.githubusercontent.com/mkbyme/shell-scripts/main/node_exporter/install_nodeexporter.sh
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

