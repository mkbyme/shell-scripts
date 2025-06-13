# Bước 1: Cài đặt dịch vụ nvidia_gpu_exporter

## Cài đặt online

Môi trường: CentOS/Ubuntu
Yêu cầu: Mạng mở thông tới github.com

```sh
# tải file
curl -O https://raw.githubusercontent.com/mkbyme/shell-scripts/main/nvidia_gpu_exporter/install_gpuexporter.sh
sudo bash install_gpuexporter.sh
```

Chạy file `install_gpuexporter.sh` để cài đặt

Sau đó mở trình duyệt tại đường dẫn http://hostname:9835/metrics để kiểm tra dịch vụ đã hoạt động chưa

## Cài đặt offline

Tải file .deb phù hợp từ [tại đây](https://github.com/utkuozdemir/nvidia_gpu_exporter/releases)

Sau đó copy lên máy chủ và cài đặt bằng script dưới đây.

```sh
# di chuyển về thư mục chứa file deb
cd ~
# cài đặt
sudo bash install_gpuexporter.sh --version 1.3.2
```

## Hướng dẫn cài đặt hàng loạt qua anisible

Sử dụng file playbook tại [anisible.yml](/nvidia_gpu_exporter/anisible.yml)

Hoặc copy nội dung bên dưới

```yaml
tasks:
  - name: Transfer script
    copy: src=/tmp/script_setup_gpuexporter/install_gpuexporter.sh dest=/tmp/nvidia_gpu_exporter mode=0755
```
