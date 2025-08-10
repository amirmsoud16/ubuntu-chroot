# Ubuntu Chroot 360MB - Poco X3 Pro PixelOS

نصب محیط Ubuntu Chroot بهینه‌سازی شده برای گوشی Poco X3 Pro با سیستم‌عامل PixelOS

## 🚀 نصب سریع

### پیش‌نیازها
```bash
# 1. نصب Termux از F-Droid یا GitHub
# 2. اعطای مجوز Storage به Termux
termux-setup-storage

# 3. به‌روزرسانی پکیج‌های Termux
pkg update && pkg upgrade -y

# 4. کلون کردن فایل‌های نصب
curl -O https://raw.githubusercontent.com/your-repo/install_ubuntu_termux.sh
curl -O https://raw.githubusercontent.com/your-repo/setup_ubuntu_root.sh
```

## 📋 مراحل نصب

### مرحله اول: نصب پایه (در Termux)
```bash
bash install_ubuntu_termux.sh
```
**این مرحله شامل:**
- تشخیص خودکار محیط و دستگاه
- دانلود Ubuntu rootfs (360MB)
- استخراج و پیکربندی اولیه
- ایجاد اسکریپت‌های راه‌اندازی

### مرحله دوم: تنظیمات پیشرفته (نیاز به Root)
```bash
su -c 'bash setup_ubuntu_root.sh'
```
**این مرحله شامل:**
- Mount کردن فایل‌سیستم‌های ضروری
- پیکربندی GPU Adreno 640
- تنظیم DNS بهینه
- فعال‌سازی دسترسی‌های سخت‌افزاری

## ⚡ راه‌اندازی

### شروع Ubuntu
```bash
ubuntu
```
یا
```bash
~/start-ubuntu.sh
```

### خروج از Ubuntu
```bash
exit
```

### Unmount کردن (در صورت نیاز)
```bash
su -c '~/unmount-ubuntu.sh'
```

## 🎯 ویژگی‌های کلیدی

- **🔧 تشخیص خودکار**: Poco X3 Pro و PixelOS
- **🎮 پشتیبانی GPU**: Adreno 640 کاملاً فعال
- **🌐 DNS بهینه**: چندین سرور DNS با تنظیمات موبایل
- **📱 دو روش نصب**: chroot (روت) یا proot (غیر روت)
- **🎨 رابط زیبا**: نوار پیشرفت و انیمیشن‌های رنگی
- **⚡ نصب خودکار**: بدون نیاز به تعامل کاربر

## 📊 مشخصات سیستم

| ویژگی | مقدار |
|--------|--------|
| حجم نهایی | ~360MB |
| نسخه Ubuntu | 22.04 LTS (Jammy) |
| معماری | ARM64 |
| GPU | Adreno 640 |
| ROM | PixelOS |

## 🛠️ عیب‌یابی

### مشکلات رایج:

**خطای دسترسی Storage:**
```bash
termux-setup-storage
```

**خطای شبکه:**
```bash
pkg install wget curl
```

**مشکل Root:**
```bash
# برای غیر روت:
bash install_ubuntu_termux.sh

# برای روت:
su -c 'bash setup_ubuntu_root.sh'
```

**بازنشانی کامل:**
```bash
rm -rf ~/ubuntu-chroot
su -c '~/unmount-ubuntu.sh'
```

## 📞 پشتیبانی

- **دستگاه هدف**: Poco X3 Pro (vayu)
- **سیستم‌عامل**: PixelOS
- **محیط**: Termux + Ubuntu Chroot
- **GPU**: Adreno 640 با پشتیبانی کامل

---

**نکته**: این اسکریپت‌ها به‌طور خاص برای Poco X3 Pro با PixelOS بهینه‌سازی شده‌اند اما روی سایر دستگاه‌های ARM64 نیز کار می‌کنند.

🚀 **Ubuntu Chroot آماده استفاده است!**
