# ubuntu-chroot (Magisk chroot Ubuntu)

محیط دسکتاپ (XFCE + VNC) و ابزارهای ضروری داخل Ubuntu در chroot (Magisk). اسکریپت‌ها برای chroot بهینه شده‌اند و بدون وابستگی به Termux کار می‌کنند.

## پیش‌نیازها
- Ubuntu chroot (Magisk) اجرا و وارد آن شده باشید.
- دسترسی روت داخل chroot.
- اینترنت پایدار.

## نصب سریع
```bash
sudo apt-get update -y
sudo apt-get install -y git

sudo git clone https://github.com/amirmsoud16/ubuntu-chroot.git
cd ubuntu-chroot/distro

sudo bash gui.sh
```
