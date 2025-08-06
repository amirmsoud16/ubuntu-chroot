#!/bin/bash

# فایل 3: فیکس کردن اینترنت

echo "=== فیکس اینترنت ==="

CHROOT_DIR="/tmp/ubuntu-chroot"

# بررسی root
if [ "$EUID" -ne 0 ]; then
    echo "خطا: با sudo اجرا کنید"
    exit 1
fi

# حذف فایل قبلی و تنظیم DNS جدید
echo "تنظیم DNS..."
rm -f $CHROOT_DIR/etc/resolv.conf

# DNS پشتیبان
cat > $CHROOT_DIR/etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

echo "اینترنت فیکس شد!"
echo "برای تست: sudo chroot /tmp/ubuntu-chroot /bin/bash"
echo "سپس: ping google.com"
