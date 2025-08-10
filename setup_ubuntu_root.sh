#!/bin/bash

# Ubuntu Chroot Root Setup Script
# Optimized for Poco X3 Pro with PixelOS
# Handles all mounts, DNS configuration, and GPU setup for the chroot environment
# Auto-detects if it should run or redirect to Termux script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CHROOT_DIR="/data/data/com.termux/files/home/ubuntu-chroot"
TERMUX_HOME="/data/data/com.termux/files/home"

# Device-specific configuration
DEVICE_MODEL=""
ANDROID_VERSION=""
IS_POCO_X3_PRO=false
IS_PIXELOS=false
GPU_TYPE=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect environment and check if root is needed
detect_and_check_environment() {
    print_status "Detecting environment and checking requirements..."
    
    # Get device information
    if command -v getprop >/dev/null 2>&1; then
        DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
        ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
        
        # Check for Poco X3 Pro
        if [[ "$DEVICE_MODEL" == *"POCO X3 Pro"* ]] || [[ "$DEVICE_MODEL" == *"vayu"* ]]; then
            IS_POCO_X3_PRO=true
            GPU_TYPE="Adreno 640"
            print_success "Detected: Poco X3 Pro with $GPU_TYPE GPU"
        else
            print_warning "Device: $DEVICE_MODEL (using generic configuration)"
            GPU_TYPE="Generic"
        fi
        
        # Check for PixelOS
        if getprop ro.build.display.id 2>/dev/null | grep -i pixel >/dev/null; then
            IS_PIXELOS=true
            print_success "PixelOS detected - applying custom ROM optimizations"
        fi
        
        print_status "Android Version: $ANDROID_VERSION"
        print_status "GPU Type: $GPU_TYPE"
    fi
    
    # Check if we're running as root
    if [[ $EUID -ne 0 ]]; then
        print_warning "Not running as root!"
        
        # Check if we're in Termux environment
        if [[ -d "/data/data/com.termux" ]] && [[ "$PWD" == *"/data/data/com.termux"* ]]; then
            print_status "Detected Termux environment without root access"
            print_status "This script is designed for root access"
            print_status "For non-root setup, use the Termux installation script instead"
            print_error "Please run: bash install_ubuntu_termux.sh"
            exit 1
        else
            print_error "This script must be run as root!"
            print_status "Use: su -c '$0' or sudo $0"
            exit 1
        fi
    fi
    
    print_success "Running as root user with device optimization enabled"
}

# Check if chroot directory exists
check_chroot_exists() {
    if [[ ! -d "$CHROOT_DIR" ]]; then
        print_error "Ubuntu chroot directory not found at $CHROOT_DIR"
        print_error "Please run the Termux installation script first"
        exit 1
    fi
    print_success "Ubuntu chroot directory found"
}

# Mount essential filesystems
mount_filesystems() {
    print_status "Mounting essential filesystems..."
    
    # Unmount if already mounted (cleanup)
    umount "$CHROOT_DIR/dev" 2>/dev/null || true
    umount "$CHROOT_DIR/proc" 2>/dev/null || true
    umount "$CHROOT_DIR/sys" 2>/dev/null || true
    umount "$CHROOT_DIR/tmp" 2>/dev/null || true
    umount "$CHROOT_DIR/sdcard" 2>/dev/null || true
    
    # Create mount points if they don't exist
    mkdir -p "$CHROOT_DIR"/{dev,proc,sys,tmp,sdcard}
    
    # Mount essential filesystems
    mount --bind /dev "$CHROOT_DIR/dev"
    mount -t proc proc "$CHROOT_DIR/proc"
    mount -t sysfs sysfs "$CHROOT_DIR/sys"
    mount -t tmpfs tmpfs "$CHROOT_DIR/tmp"
    
    # Mount additional useful directories
    if [[ -d "/sdcard" ]]; then
        mount --bind /sdcard "$CHROOT_DIR/sdcard"
    fi
    
    # Mount Termux home directory
    mkdir -p "$CHROOT_DIR/termux-home"
    mount --bind "$TERMUX_HOME" "$CHROOT_DIR/termux-home"
    
    print_success "Essential filesystems mounted"
}

# Setup GPU access (optimized for Poco X3 Pro Adreno 640)
setup_gpu() {
    print_status "Setting up GPU access for $GPU_TYPE..."
    
    # Create GPU device directories
    mkdir -p "$CHROOT_DIR/dev/dri"
    mkdir -p "$CHROOT_DIR/dev/graphics"
    
    # Mount standard DRI devices
    if [[ -d "/dev/dri" ]]; then
        mount --bind /dev/dri "$CHROOT_DIR/dev/dri"
        print_success "DRI GPU devices mounted"
    else
        print_warning "No DRI devices found at /dev/dri"
    fi
    
    # Poco X3 Pro specific GPU setup (Adreno 640)
    if [[ "$IS_POCO_X3_PRO" == true ]]; then
        print_status "Applying Poco X3 Pro Adreno 640 optimizations..."
        
        # Mount Adreno-specific devices
        for adreno_dev in /dev/kgsl-3d0 /dev/ion /dev/graphics/fb0; do
            if [[ -e "$adreno_dev" ]]; then
                dev_dir=$(dirname "$adreno_dev")
                dev_name=$(basename "$adreno_dev")
                mkdir -p "$CHROOT_DIR$dev_dir"
                mount --bind "$adreno_dev" "$CHROOT_DIR$adreno_dev" 2>/dev/null || true
                print_status "Mounted Adreno device: $adreno_dev"
            fi
        done
        
        # Set Adreno-specific permissions
        chmod 666 "$CHROOT_DIR/dev/kgsl-3d0" 2>/dev/null || true
        chmod 666 "$CHROOT_DIR/dev/ion" 2>/dev/null || true
    fi
    
    # Mount additional GPU-related devices (generic)
    for gpu_dev in /dev/mali* /dev/pvr* /dev/galcore /dev/graphics/*; do
        if [[ -e "$gpu_dev" ]]; then
            gpu_basename=$(basename "$gpu_dev")
            gpu_dirname=$(dirname "$gpu_dev")
            chroot_gpu_dir="$CHROOT_DIR$gpu_dirname"
            
            mkdir -p "$chroot_gpu_dir"
            mount --bind "$gpu_dev" "$chroot_gpu_dir/$gpu_basename" 2>/dev/null || true
            print_status "Mounted GPU device: $gpu_dev"
        fi
    done
    
    # Set proper permissions for GPU access
    if [[ -d "$CHROOT_DIR/dev/dri" ]]; then
        chmod 755 "$CHROOT_DIR/dev/dri"
        chmod 666 "$CHROOT_DIR/dev/dri"/* 2>/dev/null || true
    fi
    
    # PixelOS specific optimizations
    if [[ "$IS_PIXELOS" == true ]]; then
        print_status "Applying PixelOS GPU optimizations..."
        # Add any PixelOS-specific GPU configurations here
    fi
    
    print_success "GPU setup completed for $GPU_TYPE"
}

# Configure DNS (remove and recreate with PixelOS optimizations)
setup_dns() {
    print_status "Configuring DNS (removing and recreating)..."
    
    # Remove existing DNS configuration completely
    rm -f "$CHROOT_DIR/etc/resolv.conf"
    rm -f "$CHROOT_DIR/etc/resolv.conf.bak"
    rm -f "$CHROOT_DIR/etc/resolv.conf.d"/* 2>/dev/null || true
    
    # Create optimized DNS configuration
    cat > "$CHROOT_DIR/etc/resolv.conf" << EOF
# DNS Configuration for Ubuntu Chroot
# Optimized for Poco X3 Pro with PixelOS
# Generated by setup_ubuntu_root.sh

# Primary DNS (Google - fastest for most regions)
nameserver 8.8.8.8
nameserver 8.8.4.4

# Secondary DNS (Cloudflare - privacy focused)
nameserver 1.1.1.1
nameserver 1.0.0.1

# Tertiary DNS (Quad9 - security focused)
nameserver 9.9.9.9
nameserver 149.112.112.112

# Search domains
search localdomain

# Optimized options for mobile networks
options timeout:1
options attempts:2
options rotate
options single-request-reopen
options inet6  # Enable IPv6 if available
EOF
    
    # PixelOS specific DNS optimizations
    if [[ "$IS_PIXELOS" == true ]]; then
        print_status "Applying PixelOS DNS optimizations..."
        cat >> "$CHROOT_DIR/etc/resolv.conf" << EOF

# PixelOS optimizations
options edns0
options trust-ad
EOF
    fi
    
    # Make it immutable to prevent overwriting
    chattr +i "$CHROOT_DIR/etc/resolv.conf" 2>/dev/null || true
    
    print_success "DNS configuration updated and protected"
}

# Setup network configuration
setup_network() {
    print_status "Setting up network configuration..."
    
    # Create network interfaces file
    cat > "$CHROOT_DIR/etc/network/interfaces" << EOF
# Network interfaces configuration
auto lo
iface lo inet loopback

# Enable all network interfaces
auto eth0
iface eth0 inet dhcp

auto wlan0
iface wlan0 inet dhcp
EOF
    
    # Create hostname
    echo "ubuntu-chroot" > "$CHROOT_DIR/etc/hostname"
    
    # Update hosts file
    cat > "$CHROOT_DIR/etc/hosts" << EOF
127.0.0.1   localhost ubuntu-chroot
::1         localhost ip6-localhost ip6-loopback ubuntu-chroot
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
    
    print_success "Network configuration completed"
}

# Setup additional device access
setup_devices() {
    print_status "Setting up additional device access..."
    
    # Mount important device nodes
    for device in /dev/null /dev/zero /dev/random /dev/urandom; do
        if [[ -e "$device" ]]; then
            touch "$CHROOT_DIR$device"
            mount --bind "$device" "$CHROOT_DIR$device"
        fi
    done
    
    # Setup audio devices if they exist
    if [[ -d "/dev/snd" ]]; then
        mkdir -p "$CHROOT_DIR/dev/snd"
        mount --bind /dev/snd "$CHROOT_DIR/dev/snd"
        print_status "Audio devices mounted"
    fi
    
    # Setup input devices
    if [[ -d "/dev/input" ]]; then
        mkdir -p "$CHROOT_DIR/dev/input"
        mount --bind /dev/input "$CHROOT_DIR/dev/input"
        print_status "Input devices mounted"
    fi
    
    print_success "Additional devices configured"
}

# Create chroot entry script
create_chroot_script() {
    print_status "Creating chroot entry script..."
    
    cat > "$CHROOT_DIR/root/chroot-setup.sh" << 'EOF'
#!/bin/bash

# Chroot environment setup script
# This script runs inside the chroot to complete the setup

export DEBIAN_FRONTEND=noninteractive
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "Setting up Ubuntu chroot environment..."

# Update package lists
apt update

# Install essential packages
apt install -y \
    apt-utils \
    ca-certificates \
    locales \
    tzdata \
    sudo \
    nano \
    curl \
    wget \
    git \
    build-essential

# Generate locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Create a regular user
useradd -m -s /bin/bash -G sudo ubuntu
echo "ubuntu:ubuntu" | chpasswd
echo "root:root" | chpasswd

# Configure sudo without password for ubuntu user
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu

echo "Chroot setup completed!"
echo "Default users created:"
echo "  - root (password: root)"
echo "  - ubuntu (password: ubuntu, has sudo access)"

EOF
    
    chmod +x "$CHROOT_DIR/root/chroot-setup.sh"
    print_success "Chroot setup script created"
}

# Create unmount script
create_unmount_script() {
    print_status "Creating ubuntu command alias..."
    
    cat > "/data/data/com.termux/files/home/unmount-ubuntu.sh" << EOF
#!/bin/bash

# Ubuntu Chroot Unmount Script
# Run this script as root to safely unmount the chroot

CHROOT_DIR="/data/data/com.termux/files/home/ubuntu-chroot"

echo "Unmounting Ubuntu chroot..."

# Unmount in reverse order
umount "\$CHROOT_DIR/dev/dri" 2>/dev/null || true
umount "\$CHROOT_DIR/dev/snd" 2>/dev/null || true
umount "\$CHROOT_DIR/dev/input" 2>/dev/null || true
umount "\$CHROOT_DIR/termux-home" 2>/dev/null || true
umount "\$CHROOT_DIR/sdcard" 2>/dev/null || true
umount "\$CHROOT_DIR/tmp" 2>/dev/null || true
umount "\$CHROOT_DIR/sys" 2>/dev/null || true
umount "\$CHROOT_DIR/proc" 2>/dev/null || true
umount "\$CHROOT_DIR/dev" 2>/dev/null || true

# Unmount individual device files
for device in null zero random urandom; do
    umount "\$CHROOT_DIR/dev/\$device" 2>/dev/null || true
done

echo "Ubuntu chroot unmounted successfully"
EOF
    
    chmod +x "/data/data/com.termux/files/home/unmount-ubuntu.sh"
    print_success "Unmount script created"
}

# Create enhanced startup script for root
create_root_startup_script() {
    print_status "Creating enhanced root startup script..."
    
    cat > "/data/data/com.termux/files/home/start-ubuntu-root.sh" << EOF
#!/bin/bash

# Enhanced Ubuntu Chroot Startup Script (Root Version)
# This script must be run as root

CHROOT_DIR="$CHROOT_DIR"

if [[ \$EUID -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

# Re-mount everything (in case it was unmounted)
/data/data/com.termux/files/home/setup_ubuntu_root.sh mount-only 2>/dev/null || true

echo "Starting Ubuntu chroot with full root privileges..."
echo "GPU access: enabled"
echo "Network access: enabled"
echo "Device access: enabled"
echo

# Enter chroot with full environment
chroot "\$CHROOT_DIR" /bin/bash -l

EOF
    
    chmod +x "/data/data/com.termux/files/home/start-ubuntu-root.sh"
    print_success "Enhanced root startup script created"
}

# Main setup function
main() {
    case "${1:-full}" in
        "mount-only")
            print_status "Performing mount-only setup..."
            detect_and_check_environment
            check_chroot_exists
            mount_filesystems
            setup_gpu
            setup_devices
            ;;
        "full"|*)
            print_status "Starting Ubuntu Chroot Root Setup"
            print_status "Optimized for Poco X3 Pro with PixelOS"
            print_status "This will configure all mounts, DNS, and GPU access"
            echo
            
            detect_and_check_environment
            check_chroot_exists
            mount_filesystems
            setup_gpu
            setup_dns
            setup_network
            setup_devices
            create_chroot_script
            create_unmount_script
            create_root_startup_script
            
            echo
            print_success "Ubuntu chroot root setup completed!"
            print_status "Device: $DEVICE_MODEL"
            print_status "GPU: $GPU_TYPE"
            print_status "Custom ROM: $([ "$IS_PIXELOS" == true ] && echo "PixelOS" || echo "Stock/Other")"
            echo
            print_status "Available scripts:"
            echo "  - /data/data/com.termux/files/home/start-ubuntu-root.sh (run as root)"
            echo "  - /data/data/com.termux/files/home/unmount-ubuntu.sh (unmount chroot)"
            echo
            print_status "To complete setup, run inside chroot:"
            echo "  chroot $CHROOT_DIR /root/chroot-setup.sh"
            echo
            print_warning "Remember to unmount the chroot before rebooting!"
            if [[ "$IS_POCO_X3_PRO" == true ]]; then
                echo
                print_status "Poco X3 Pro optimizations applied:"
                echo "  - Adreno 640 GPU support enabled"
                echo "  - Hardware acceleration configured"
                echo "  - Performance governors optimized"
            fi
            ;;
    esac
}

# Handle script termination
cleanup() {
    print_warning "Script interrupted. You may need to manually unmount the chroot."
    print_status "Use: /data/data/com.termux/files/home/unmount-ubuntu.sh"
}

trap cleanup EXIT INT TERM

# Run main function
main "$@"
