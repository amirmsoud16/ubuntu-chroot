#!/bin/bash

# فایل 2: مونت کردن محیط chroot

echo "=== مونت کردن محیط chroot ==="

CHROOT_DIR="/tmp/ubuntu-chroot"

# بررسی root
if [ "$EUID" -ne 0 ]; then
    echo "خطا: با sudo اجرا کنید"
    exit 1
fi

# مونت کردن
echo "در حال مونت..."
mount -t proc /proc $CHROOT_DIR/proc
mount -t sysfs /sys $CHROOT_DIR/sys
mount --rbind /dev $CHROOT_DIR/dev
mount --rbind /run $CHROOT_DIR/run

echo "مونت تمام شد!"
echo "برای ورود: sudo chroot /tmp/ubuntu-chroot /bin/bash"
