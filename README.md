# Ubuntu Chroot for Android Termux

Simple Ubuntu 24.04 LTS installation on Android Termux with root support.

## Quick Install

### Download
```bash
apt update -y
apt upgrade -y
apt install git wget curl tar
```
```
git clone https://github.com/amirmsoud16/ubuntu-chroot.git
cd ubuntu-chroot
```

### Install
```bash
# Step 1: Termux Setup (No Root Required)
chmod +x step1_termux_setup_en.sh
./step1_termux_setup_en.sh

# Step 2: Root Mount (Root Required)
chmod +x step2_root_mount_en.sh
su -c 'bash step2_root_mount_en.sh'
```

### Launch Ubuntu
```bash
ubuntu
```

## Features

- Ubuntu 24.04 LTS (28MB download)
- Works with and without root
- GPU and audio support (with root)
- Simple installation process
- English and Persian versions

## Requirements

- Android 7+
- Termux from F-Droid
- 100MB free space
- Root access (optional, for full features)

## Files

- `step1_termux_setup_en.sh` - Termux setup (English)
- `step2_root_mount_en.sh` - Root mount (English)
- `step1_termux_setup.sh` - Termux setup (Persian)
- `step2_root_mount.sh` - Root mount (Persian)

## Support

Default login:
- User: `user` / Password: `ubuntu`
- Root: `root` / Password: `ubuntu`
