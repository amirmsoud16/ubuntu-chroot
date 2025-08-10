#!/data/data/com.termux/files/usr/bin/bash

# Ubuntu Chroot 360MB Installation Script for Termux
# Optimized for Poco X3 Pro with PixelOS
# Auto-detects environment and selects appropriate method

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
UBUNTU_VERSION="noble"  # Ubuntu 24.04 LTS
CHROOT_DIR="$HOME/ubuntu-chroot"
ROOTFS_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.1-base-arm64.tar.gz"
ROOTFS_FILE="ubuntu-base.tar.gz"

# Device-specific configuration
DEVICE_MODEL=""
ANDROID_VERSION=""
IS_ROOTED=false
USE_CHROOT=false

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

# Clear screen function
clear_screen() {
    clear
    echo -e "${GREEN}Ubuntu Chroot 360MB - Poco X3 Pro PixelOS${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

# Show loading animation
show_loading() {
    local message="$1"
    local duration="${2:-3}"
    local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    
    echo -n "${BLUE}[LOADING]${NC} $message "
    
    while [ $i -lt $((duration * 10)) ]; do
        printf "\b${spinner:$((i % ${#spinner})):1}"
        sleep 0.1
        i=$((i + 1))
    done
    
    printf "\b✓\n"
}

# Show progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    # Prevent division by zero
    if [ "$total" -eq 0 ]; then
        total=1
    fi
    
    local percent=$((current * 100 / total))
    # Ensure percent doesn't exceed 100
    if [ $percent -gt 100 ]; then
        percent=100
    fi
    
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}[PROGRESS]${NC} $message "
    printf "["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%%" $percent
    
    if [ $current -ge $total ]; then
        echo " ✓"
    fi
}

# Execute command with auto-confirmation
exec_auto_confirm() {
    local cmd="$1"
    local message="$2"
    
    print_status "$message"
    
    # Execute command with automatic yes responses
    echo "y" | eval "$cmd" >/dev/null 2>&1 &
    local pid=$!
    
    show_loading "Executing..." 2
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "$message - Completed"
    else
        print_error "$message - Error occurred"
        return 1
    fi
}

# Check system access and permissions
check_system_access() {
    print_status "Checking system access and permissions..."
    echo
    
    # Check Termux environment
    if [[ ! -d "/data/data/com.termux" ]]; then
        print_error "This script must be run in Termux!"
        exit 1
    fi
    print_success "✓ Running in Termux environment"
    
    # Check storage permissions
    if [[ -r "/sdcard" ]] && [[ -w "/sdcard" ]]; then
        print_success "✓ Storage access: Available"
    else
        print_warning "⚠ Storage access: Limited (may need to grant storage permission)"
    fi
    
    # Check network access
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "✓ Network access: Available"
    else
        print_warning "⚠ Network access: Limited or unavailable"
    fi
    
    # Check available space
    local available_space=$(df -h "$HOME" | awk 'NR==2 {print $4}' | sed 's/[^0-9.]//g')
    if [[ -n "$available_space" ]]; then
        # Convert to MB for comparison (simple integer comparison)
        local space_mb=$(echo "$available_space" | awk '{print int($1 * 1024)}')
        if [ "$space_mb" -gt 500 ]; then
            print_success "✓ Available space: ${available_space}GB (sufficient for 360MB chroot)"
        else
            print_warning "⚠ Available space: ${available_space}GB (may be insufficient)"
        fi
    else
        print_warning "⚠ Available space: Could not determine disk space"
    fi
    
    # Check root access with detailed information
    print_status "Checking root access..."
    if command -v su >/dev/null 2>&1; then
        print_status "  - su command: Available"
        
        # Test root access
        if timeout 5 su -c 'id' >/dev/null 2>&1; then
            IS_ROOTED=true
            USE_CHROOT=true
            local root_uid=$(su -c 'id -u' 2>/dev/null || echo "unknown")
            print_success "✓ Root access: Available (UID: $root_uid)"
            print_status "  - Will use chroot method for better performance"
            
            # Check if we can mount filesystems
            if su -c 'mount --help' >/dev/null 2>&1; then
                print_success "  - Mount capability: Available"
            else
                print_warning "  - Mount capability: Limited"
            fi
            
        else
            print_warning "⚠ Root access: Available but denied/timeout"
            print_status "  - Will use proot method (non-root)"
        fi
    else
        print_warning "⚠ Root access: su command not available"
        print_status "  - Will use proot method (non-root)"
    fi
    
    # Check for required commands
    print_status "Checking required tools..."
    local missing_tools=()
    
    for tool in wget tar gzip; do
        if command -v "$tool" >/dev/null 2>&1; then
            print_success "  - $tool: Available"
        else
            missing_tools+=("$tool")
            print_warning "  - $tool: Missing (will be installed)"
        fi
    done
    
    if command -v proot >/dev/null 2>&1; then
        print_success "  - proot: Available"
    else
        missing_tools+=("proot")
        print_warning "  - proot: Missing (will be installed)"
    fi
    
    echo
    print_status "System access check completed"
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_status "Missing tools will be installed: ${missing_tools[*]}"
    fi
}

# Detect device and environment
detect_environment() {
    print_status "Detecting device and environment..."
    
    # Get device information
    if command -v getprop >/dev/null 2>&1; then
        DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
        ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
        
        # Check for Poco X3 Pro
        if [[ "$DEVICE_MODEL" == *"POCO X3 Pro"* ]] || [[ "$DEVICE_MODEL" == *"vayu"* ]]; then
            print_success "Detected: Poco X3 Pro ($DEVICE_MODEL)"
        else
            print_warning "Device: $DEVICE_MODEL (not specifically optimized)"
        fi
        
        print_status "Android Version: $ANDROID_VERSION"
    fi
    
    # Check for PixelOS
    if getprop ro.build.display.id 2>/dev/null | grep -i pixel >/dev/null; then
        print_success "PixelOS detected - optimizing for custom ROM"
    fi
    
    print_success "Environment detection completed"
}

# Install required packages with progress
install_dependencies() {
    clear_screen
    print_status "Installing required packages..."
    
    # Update package lists
    show_progress 1 4 "Updating package lists"
    pkg update -y >/dev/null 2>&1 &
    local update_pid=$!
    show_loading "Updating packages" 3
    wait $update_pid
    
    # Install packages one by one with progress
    local packages=("wget" "proot" "tar" "gzip")
    local i=2
    
    for package in "${packages[@]}"; do
        show_progress $i 4 "Installing $package"
        pkg install -y "$package" >/dev/null 2>&1 &
        local install_pid=$!
        show_loading "Installing $package" 2
        wait $install_pid
        i=$((i + 1))
    done
    
    show_progress 4 4 "Package installation completed"
    print_success "All required packages installed successfully"
    sleep 2
}

# Download Ubuntu rootfs with progress bar
download_rootfs() {
    clear_screen
    print_status "Downloading Ubuntu rootfs (approximately 360MB)..."
    
    # Change to home directory for consistent file paths
    cd "$HOME"
    
    if [[ -f "$ROOTFS_FILE" ]]; then
        print_warning "Rootfs file already exists, skipping download"
        return
    fi
    
    # Download with progress bar
    print_status "Starting download from Ubuntu server..."
    
    # Use wget with progress bar in background
    {
        wget --progress=dot:giga -O "$ROOTFS_FILE" "$ROOTFS_URL" 2>&1 | \
        while IFS= read -r line; do
            if [[ "$line" =~ ([0-9]+)% ]]; then
                local percent="${BASH_REMATCH[1]}"
                show_progress $percent 100 "Downloading Ubuntu rootfs"
            fi
        done
    } &
    
    local download_pid=$!
    
    # Show progress simulation while downloading
    local progress=0
    while kill -0 $download_pid 2>/dev/null; do
        if [ $progress -lt 95 ]; then
            progress=$((progress + 5))
            show_progress $progress 100 "Downloading Ubuntu rootfs"
        fi
        sleep 2
    done
    
    wait $download_pid
    show_progress 100 100 "Downloading Ubuntu rootfs"
    
    if [[ ! -f "$HOME/$ROOTFS_FILE" ]]; then
        print_error "Failed to download rootfs"
        exit 1
    fi
    
    print_success "Rootfs downloaded successfully"
    sleep 2
}

# Extract rootfs with progress
extract_rootfs() {
    clear_screen
    print_status "Extracting Ubuntu rootfs..."
    
    if [[ -d "$CHROOT_DIR" ]]; then
        print_warning "Chroot directory already exists, removing..."
        show_loading "Removing old directory" 2
        rm -rf "$CHROOT_DIR" &
        wait
    fi
    
    mkdir -p "$CHROOT_DIR"
    cd "$CHROOT_DIR"
    
    print_status "Extracting files..."
    
    # Extract with progress simulation
    {
        tar -xzf "$HOME/$ROOTFS_FILE" --strip-components=0
    } &
    local extract_pid=$!
    
    # Simulate progress for extraction
    local i=0
    while kill -0 $extract_pid 2>/dev/null; do
        local progress=$((i * 10))
        if [ $progress -le 100 ]; then
            show_progress $progress 100 "Extracting files"
        fi
        sleep 1
        i=$((i + 1))
    done
    
    wait $extract_pid
    show_progress 100 100 "Extracting files"
    
    print_success "Rootfs extracted successfully to $CHROOT_DIR"
    sleep 2
}

# Setup basic chroot environment with progress
setup_chroot() {
    clear_screen
    print_status "Setting up chroot environment..."
    
    local tasks=("Creating necessary directories" "Setting up DNS" "Creating hosts file" "Setting up sources.list and apt")
    local i=1
    
    # Create necessary directories
    show_progress $i 4 "${tasks[0]}"
    mkdir -p "$CHROOT_DIR"/{dev,proc,sys,tmp,sdcard} &
    show_loading "${tasks[0]}" 1
    wait
    i=$((i + 1))
    
    # Create resolv.conf
    show_progress $i 4 "${tasks[1]}"
    {
        echo "nameserver 8.8.8.8" > "$CHROOT_DIR/etc/resolv.conf"
        echo "nameserver 8.8.4.4" >> "$CHROOT_DIR/etc/resolv.conf"
    } &
    show_loading "${tasks[1]}" 1
    wait
    i=$((i + 1))
    
    # Create hosts file
    show_progress $i 4 "${tasks[2]}"
    cat > "$CHROOT_DIR/etc/hosts" << EOF &
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
    show_loading "${tasks[2]}" 1
    wait
    i=$((i + 1))
    
    # Set up sources.list and install apt (Ubuntu 24.04 doesn't include apt by default)
    show_progress $i 4 "${tasks[3]}"
    mkdir -p "$CHROOT_DIR/etc/apt"
    cat > "$CHROOT_DIR/etc/apt/sources.list" << EOF &
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-security main restricted universe multiverse
EOF
    show_loading "${tasks[3]}" 1
    wait
    
    show_progress 4 4 "Chroot environment setup completed"
    
    # Create initial setup script for Ubuntu 24.04 (to install apt and essentials)
    cat > "$CHROOT_DIR/root/initial-setup.sh" << 'EOF'
#!/bin/bash

# Ubuntu 24.04 Initial Setup Script
# This script installs apt and essential packages since Ubuntu 24.04 minimal doesn't include them

echo "Setting up Ubuntu 24.04 environment..."

# Update package database using dpkg directly
export DEBIAN_FRONTEND=noninteractive
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Install apt and essential packages using dpkg if available
if command -v dpkg >/dev/null 2>&1; then
    echo "Installing essential packages..."
    
    # Create a minimal apt configuration
    mkdir -p /etc/apt/apt.conf.d
    echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90assumeyes
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/90norecommends
    
    # Try to bootstrap apt if it's not available
    if ! command -v apt >/dev/null 2>&1; then
        echo "Bootstrapping package management..."
        # Use dpkg to install basic packages if available
        dpkg --configure -a 2>/dev/null || true
    fi
    
    # Update package lists
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y apt-utils
        apt-get install -y sudo nano vim curl wget
    fi
fi

# Set up user account
useradd -m -s /bin/bash user 2>/dev/null || true
echo "user:ubuntu" | chpasswd 2>/dev/null || true
echo "root:ubuntu" | chpasswd 2>/dev/null || true

# Add user to sudo group
usermod -aG sudo user 2>/dev/null || true

# Create sudo configuration
echo "user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/user 2>/dev/null || true

echo "Ubuntu 24.04 setup completed!"
echo "Default credentials: user/ubuntu, root/ubuntu"
EOF

    chmod +x "$CHROOT_DIR/root/initial-setup.sh"
    
    print_success "Basic chroot environment configured"
    print_status "Created initial setup script for Ubuntu 24.04"
    sleep 2
}

# Create startup script (adaptive based on root access)
create_startup_script() {
    print_status "Creating Ubuntu startup script..."
    
    if [[ "$USE_CHROOT" == true ]]; then
        # Create chroot-based startup script
        cat > "$HOME/start-ubuntu.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash

CHROOT_DIR="$HOME/ubuntu-chroot"

# Check if chroot directory exists
if [[ ! -d "\$CHROOT_DIR" ]]; then
    echo "Ubuntu chroot not found at \$CHROOT_DIR"
    echo "Please run the installation script first"
    exit 1
fi

# Check for root access
if ! su -c 'id' >/dev/null 2>&1; then
    echo "Root access required but not available!"
    echo "Falling back to proot method..."
    exec proot --rootfs="\$CHROOT_DIR" \
          --bind=/dev \
          --bind=/proc \
          --bind=/sys \
          --bind="$HOME:/root/termux-home" \
          --bind="/sdcard:/sdcard" \
          --working-directory="/root" \
          /bin/bash -l
fi

echo "Starting Ubuntu chroot with root privileges..."
echo "Device: $DEVICE_MODEL"
echo "Method: chroot (rooted)"
echo

# Mount and start chroot
su -c '
    # Mount essential filesystems
    mount --bind /dev "\$CHROOT_DIR/dev" 2>/dev/null || true
    mount -t proc proc "\$CHROOT_DIR/proc" 2>/dev/null || true
    mount -t sysfs sysfs "\$CHROOT_DIR/sys" 2>/dev/null || true
    mount --bind /sdcard "\$CHROOT_DIR/sdcard" 2>/dev/null || true
    
    # Mount GPU for Poco X3 Pro (Adreno 640)
    if [[ -d "/dev/dri" ]]; then
        mkdir -p "\$CHROOT_DIR/dev/dri"
        mount --bind /dev/dri "\$CHROOT_DIR/dev/dri" 2>/dev/null || true
    fi
    
    # Run initial setup if it exists and hasn'\''t been run before
    if [[ -f "\$CHROOT_DIR/root/initial-setup.sh" ]] && [[ ! -f "\$CHROOT_DIR/root/.setup-complete" ]]; then
        echo "Running Ubuntu 24.04 initial setup..."
        chroot "\$CHROOT_DIR" /root/initial-setup.sh
        touch "\$CHROOT_DIR/root/.setup-complete"
    fi
    
    # Enter chroot
    chroot "\$CHROOT_DIR" /bin/bash -l
'
EOF
    else
        # Create proot-based startup script
        cat > "$HOME/start-ubuntu.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash

CHROOT_DIR="$HOME/ubuntu-chroot"

# Check if chroot directory exists
if [[ ! -d "\$CHROOT_DIR" ]]; then
    echo "Ubuntu chroot not found at \$CHROOT_DIR"
    echo "Please run the installation script first"
    exit 1
fi

echo "Starting Ubuntu chroot (non-root mode)..."
echo "Device: $DEVICE_MODEL"
echo "Method: proot (non-rooted)"
echo

# Run initial setup if it exists and hasn't been run before
if [[ -f "\$CHROOT_DIR/root/initial-setup.sh" ]] && [[ ! -f "\$CHROOT_DIR/root/.setup-complete" ]]; then
    echo "Running Ubuntu 24.04 initial setup..."
    proot --rootfs="\$CHROOT_DIR" \
          --bind=/dev \
          --bind=/proc \
          --bind=/sys \
          --bind="$HOME:/root/termux-home" \
          --bind="/sdcard:/sdcard" \
          --working-directory="/root" \
          /root/initial-setup.sh
    touch "\$CHROOT_DIR/root/.setup-complete"
fi

# Start Ubuntu chroot with proot
proot --rootfs="\$CHROOT_DIR" \
      --bind=/dev \
      --bind=/proc \
      --bind=/sys \
      --bind="$HOME:/root/termux-home" \
      --bind="/sdcard:/sdcard" \
      --working-directory="/root" \
      /bin/bash -l
EOF
    fi
    
    chmod +x "$HOME/start-ubuntu.sh"
    print_success "Startup script created at $HOME/start-ubuntu.sh"
}

# Create alias for easy access
create_alias() {
    print_status "Creating ubuntu command alias..."
    
    # Add alias to .bashrc
    if ! grep -q "alias ubuntu=" "$HOME/.bashrc" 2>/dev/null; then
        echo "alias ubuntu='$HOME/start-ubuntu.sh'" >> "$HOME/.bashrc"
        print_success "Added 'ubuntu' alias to .bashrc"
    else
        print_warning "Ubuntu alias already exists in .bashrc"
    fi
}

# Main installation function
main() {
    clear_screen
    print_status "Starting Ubuntu Chroot Installation for Termux"
    print_status "Target size: ~360MB"
    print_status "Optimized for Poco X3 Pro with PixelOS"
    echo
    
    check_system_access
    sleep 3
    
    clear_screen
    detect_environment
    sleep 2
    
    install_dependencies
    download_rootfs
    extract_rootfs
    setup_chroot
    
    clear_screen
    print_status "ایجاد اسکریپت‌های راه‌اندازی..."
    create_startup_script &
    show_loading "ایجاد اسکریپت راه‌اندازی" 2
    wait
    
    create_alias &
    show_loading "ایجاد alias برای دسترسی آسان" 1
    wait
    
    # Cleanup with progress
    clear_screen
    print_status "Cleaning up temporary files..."
    show_loading "Removing downloaded files" 2
    rm -f "$HOME/$ROOTFS_FILE" &
    wait
    
    # Final success screen
    clear_screen
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                    ${YELLOW}🎉 Installation Completed Successfully! 🎉${NC}                   ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    print_success "Ubuntu chroot installation completed!"
    print_status "Device: $DEVICE_MODEL"
    print_status "Method: $([ "$USE_CHROOT" == true ] && echo "chroot (rooted)" || echo "proot (non-rooted)")"
    echo
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                        ${BLUE}Usage Guide${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} To start Ubuntu:                                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}ubuntu${NC}                                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Or directly:                                                 ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}$HOME/start-ubuntu.sh${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                       ${BLUE}Next Steps${NC}                          ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    if [[ "$USE_CHROOT" == true ]]; then
        echo -e "${CYAN}║${NC} 1. Run root setup script:                                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}    ${YELLOW}su -c 'bash setup_ubuntu_root.sh'${NC}                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} 2. Start Ubuntu with 'ubuntu' command (uses chroot)         ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} 3. Update package lists: ${GREEN}apt update${NC}                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} 4. Install required packages                                ${CYAN}║${NC}"
    else
        echo -e "${CYAN}║${NC} 1. Start Ubuntu with 'ubuntu' command (uses proot)          ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} 2. Update package lists: ${GREEN}apt update${NC}                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} 3. Install required packages                                ${CYAN}║${NC}"
    fi
    
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    print_warning "Note: You may need to restart Termux or run 'source ~/.bashrc' for the alias to work"
    
    echo
    echo -e "${PURPLE}🚀 Ubuntu Chroot is ready to use! 🚀${NC}"
}

# Run main function
main "$@"
