#!/bin/bash

# فایل 1: دانلود و استخراج اوبونتو

echo "=== دانلود و استخراج اوبونتو ==="

# دانلود (فقط اگر فایل وجود نداشته باشد)
if [ ! -f "ubuntu-rootfs.tar.xz" ]; then
    echo "در حال دانلود..."
    wget https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-arm64-root.tar.xz -O ubuntu-rootfs.tar.xz
else
    echo "فایل از قبل موجود است، دانلود نمی‌شود"
fi

# ایجاد پوشه
mkdir -p /tmp/ubuntu-chroot

# استخراج
echo "در حال استخراج..."
tar -xf ubuntu-rootfs.tar.xz -C /tmp/ubuntu-chroot

echo "دانلود و استخراج تمام شد!"
echo "پوشه: /tmp/ubuntu-chroot"
