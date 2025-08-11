# ubuntu-chroot (Magisk chroot Ubuntu)

محیط دسکتاپ (XFCE + VNC) و ابزارهای ضروری داخل Ubuntu در chroot (Magisk). اسکریپت‌ها برای chroot بهینه شده‌اند و بدون وابستگی به Termux کار می‌کنند.

## پیش‌نیازها
- Ubuntu chroot (Magisk) اجرا و وارد آن شده باشید.
- دسترسی روت داخل chroot.
- اینترنت پایدار.

## نصب سریع
```bash
apt-get update -y
apt-get install -y git

git clone https://github.com/amirmsoud16/ubuntu-chroot.git
cd ubuntu-chroot/distro

sudo bash gui.sh
```

## اجرای دسکتاپ (VNC)
- شروع VNC:
```bash
# مقادیر اختیاری قابل تنظیم قبل از اجرا:
# VNC_DISPLAY=:1 VNC_GEOMETRY=1920x1080 VNC_DEPTH=24 VNC_NAME="ubuntu-chroot"
bash vncstart
```

- اتصال در VNC Viewer:
  - آدرس: localhost:1

- توقف VNC:
```bash
# توقف نمایش پیش‌فرض :1
bash vncstop
# یا نمایش مشخص (مثلاً :2)
bash vncstop 2
```

## نصب مرورگر
- فایرفاکس (بر اساس codename سیستم از PPA mozillateam):
```bash
sudo bash firefox.sh
```

## نکات
- متغیرهای محیطی DISPLAY و PULSE_SERVER به‌صورت پایدار در `/etc/profile.d/desktop.sh` ست می‌شوند.
- `vncstart` پارامتریک است (DISPLAY/GEOMETRY/DEPTH/NAME).
- اگر PPA برای codename شما در دسترس نبود، از نسخه‌های جایگزین (ESR/Chromium) استفاده کنید.

## رفع اشکال
- اگر VNC بالا نیامد:
  - لاگ‌ها: `~/.vnc/*.log`
  - قفل‌ها را با `bash vncstop` پاک کنید و دوباره `bash vncstart` اجرا کنید.
- اگر نصب مرورگر خطا داد:
  - `apt-get update -y` و بررسی codename (`/etc/os-release`).
  - از مرورگر جایگزین استفاده کنید.

---
ساخته‌شده برای chroot مجیسک. مشارکت و PR پذیرفته می‌شود.
