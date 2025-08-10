#!/data/data/com.termux/files/usr/bin/bash

# Ubuntu Chroot Installation - Step 1 (Termux Setup)
# Version: Ubuntu 24.04 LTS (Noble Numbat)
# Environment: Termux (No Root Required)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
UBUNTU_VERSION="noble"
CHROOT_DIR="$HOME/ubuntu-chroot"
ROOTFS_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.1-base-arm64.tar.gz"
ROOTFS_FILE="ubuntu-base.tar.gz"
TOTAL_STEPS=8

# Display functions
print_header() {
    clear
    echo "Ubuntu Chroot - Step 1 (Termux Setup)"
    echo "======================================"
    echo
}

print_priority() {
    local priority=$1
    local step=$2
    local desc="$3"
    local required="$4"
    
    local priority_color=""
    local req_text=""
    
    case $priority in
        "High") priority_color="${RED}" ;;
        "Medium") priority_color="${YELLOW}" ;;
        "Low") priority_color="${GREEN}" ;;
    esac
    
    if [[ "$required" == "Essential" ]]; then
        req_text="${RED}[Essential]${NC}"
    elif [[ "$required" == "Recommended" ]]; then
        req_text="${YELLOW}[Recommended]${NC}"
    else
        req_text="${GREEN}[Optional]${NC}"
    fi
    
    echo -e "${priority_color}[Priority $priority]${NC} ${BLUE}Step $step:${NC} $desc $req_text"
}

print_info() {
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

# Progress display
show_progress() {
    local current=$1
    local total=$2
    local message="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}[%d/%d]${NC} $message: [" $current $total
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%%" $percent
    
    if [ $current -eq $total ]; then
        echo
    fi
}

# Step 1: Check Termux environment
step1_check_termux() {
    print_header
    print_priority "High" "1" "Check Termux environment" "Essential"
    show_progress 1 $TOTAL_STEPS "Checking environment"
    
    if [[ ! -d "/data/data/com.termux" ]]; then
        print_error "Termux not found! Please install Termux from F-Droid"
        exit 1
    fi
    
    print_success "Termux environment verified"
    sleep 1
}

# Step 2: Check storage access
step2_check_storage() {
    print_priority "High" "2" "Check storage access" "Essential"
    show_progress 2 $TOTAL_STEPS "Checking permissions"
    
    if [[ ! -d "$HOME/storage" ]]; then
        print_warning "Storage access not configured"
        print_info "Running termux-setup-storage..."
        termux-setup-storage
    fi
    
    print_success "Storage access verified"
    sleep 1
}

# Step 3: Update packages
step3_update_packages() {
    print_priority "High" "3" "Update packages" "Essential"
    show_progress 3 $TOTAL_STEPS "Updating system"
    
    print_info "Updating package lists..."
    pkg update -y >/dev/null 2>&1
    
    print_info "Upgrading packages..."
    pkg upgrade -y >/dev/null 2>&1
    
    print_success "System updated"
    sleep 1
}

# Step 4: Install essential tools
step4_install_tools() {
    print_priority "High" "4" "Install essential tools" "Essential"
    show_progress 4 $TOTAL_STEPS "Installing tools"
    
    local tools=("wget" "tar" "gzip" "proot")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_info "Installing missing tools: ${missing_tools[*]}"
        pkg install -y "${missing_tools[@]}" >/dev/null 2>&1
    fi
    
    print_success "All tools ready"
    sleep 1
}

# Step 5: Download Ubuntu rootfs
step5_download_ubuntu() {
    print_priority "High" "5" "Download Ubuntu rootfs (28MB)" "Essential"
    show_progress 5 $TOTAL_STEPS "Downloading Ubuntu"
    
    cd "$HOME"
    
    if [[ -f "$ROOTFS_FILE" ]]; then
        print_warning "Ubuntu file exists, skipping download"
        return
    fi
    
    # Check disk space
    local available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 100000 ]]; then
        print_error "Insufficient disk space! At least 100MB required"
        exit 1
    fi
    
    print_info "Starting Ubuntu 24.04 download..."
    wget --progress=bar:force -O "$ROOTFS_FILE" "$ROOTFS_URL"
    
    if [[ ! -f "$ROOTFS_FILE" ]]; then
        print_error "Download failed!"
        exit 1
    fi
    
    print_success "Ubuntu downloaded successfully"
    sleep 1
}

# Step 6: Extract files
step6_extract_ubuntu() {
    print_priority "High" "6" "Extract files" "Essential"
    show_progress 6 $TOTAL_STEPS "Extracting Ubuntu"
    
    if [[ -d "$CHROOT_DIR" ]]; then
        print_warning "Removing old directory..."
        rm -rf "$CHROOT_DIR"
    fi
    
    print_info "Creating new directory..."
    mkdir -p "$CHROOT_DIR"
    
    print_info "Extracting files..."
    cd "$CHROOT_DIR"
    tar -xzf "$HOME/$ROOTFS_FILE"
    
    print_success "Files extracted successfully"
    sleep 1
}

# Step 7: Setup basic network
step7_setup_network() {
    print_priority "High" "7" "Setup basic network" "Essential"
    show_progress 7 $TOTAL_STEPS "Configuring network"
    
    # Remove old resolv.conf file
    print_info "Removing old network configuration..."
    rm -f "$CHROOT_DIR/etc/resolv.conf"
    
    # Setup new DNS
    print_info "Setting up DNS..."
    cat > "$CHROOT_DIR/etc/resolv.conf" << EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 9.9.9.9
EOF
    
    # Setup hosts
    print_info "Setting up hosts file..."
    cat > "$CHROOT_DIR/etc/hosts" << EOF
127.0.0.1   localhost ubuntu-chroot
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
    
    # Setup sources.list
    print_info "Setting up software sources..."
    mkdir -p "$CHROOT_DIR/etc/apt"
    cat > "$CHROOT_DIR/etc/apt/sources.list" << EOF
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $UBUNTU_VERSION-security main restricted universe multiverse
EOF
    
    print_success "Basic network configured"
    sleep 1
}

# Step 8: Create setup script
step8_create_setup_script() {
    print_priority "High" "8" "Create setup script" "Essential"
    show_progress 8 $TOTAL_STEPS "Creating scripts"
    
    # Create essential directories
    mkdir -p "$CHROOT_DIR"/{dev,proc,sys,tmp,sdcard}
    
    # Internal setup script
    cat > "$CHROOT_DIR/root/setup-chroot.sh" << 'EOF'
#!/bin/bash

echo "Setting up Ubuntu 24.04 environment"
echo "==================================="

export DEBIAN_FRONTEND=noninteractive
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "[1/6] Updating packages..."
apt update >/dev/null 2>&1 || true

echo "[2/6] Installing essential packages..."
apt install -y sudo nano vim curl wget ca-certificates >/dev/null 2>&1 || true

echo "[3/6] Creating user..."
useradd -m -s /bin/bash user 2>/dev/null || true
echo "user:ubuntu" | chpasswd 2>/dev/null || true
echo "root:ubuntu" | chpasswd 2>/dev/null || true

echo "[4/6] Setting up groups..."
usermod -aG sudo user 2>/dev/null || true
usermod -aG audio user 2>/dev/null || true
usermod -aG video user 2>/dev/null || true
usermod -aG input user 2>/dev/null || true
usermod -aG plugdev user 2>/dev/null || true

echo "[5/6] Configuring sudo..."
echo "user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/user 2>/dev/null || true
chmod 0440 /etc/sudoers.d/user 2>/dev/null || true

echo "[6/6] Setting up Android groups..."
groupadd -f android-audio 2>/dev/null || true
groupadd -f android-graphics 2>/dev/null || true
groupadd -f android-input 2>/dev/null || true
usermod -aG android-audio user 2>/dev/null || true
usermod -aG android-graphics user 2>/dev/null || true
usermod -aG android-input user 2>/dev/null || true

echo "Ubuntu setup completed!"
echo "User: user | Password: ubuntu"
echo "Root: root | Password: ubuntu"
EOF
    
    chmod +x "$CHROOT_DIR/root/setup-chroot.sh"
    
    # Simple launcher script (proot)
    cat > "$HOME/ubuntu-proot.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash

CHROOT_DIR="$HOME/ubuntu-chroot"

if [[ ! -d "\$CHROOT_DIR" ]]; then
    echo "Error: Ubuntu not found!"
    exit 1
fi

echo "Starting Ubuntu 24.04 (proot mode)..."

proot --rootfs="\$CHROOT_DIR" \\
      --bind=/dev \\
      --bind=/proc \\
      --bind=/sys \\
      --bind="$HOME:/root/termux-home" \\
      --bind="/sdcard:/sdcard" \\
      --working-directory="/root" \\
      /bin/bash -l
EOF
    
    chmod +x "$HOME/ubuntu-proot.sh"
    
    print_success "Setup scripts created"
    sleep 1
}

# Cleanup
cleanup() {
    print_info "Cleaning up temporary files..."
    if [[ -f "$HOME/$ROOTFS_FILE" ]]; then
        rm -f "$HOME/$ROOTFS_FILE"
        print_success "Download file removed"
    fi
}

# Show result
show_result() {
    print_header
    echo "Step 1 Completed Successfully!"
    echo "=============================="
    echo
    
    print_success "Ubuntu 24.04 Chroot prepared!"
    echo
    
    echo "Installation Info:"
    echo "  • Version: Ubuntu 24.04 LTS (Noble)"
    echo "  • Path: $CHROOT_DIR"
    echo "  • Size: 28MB (compressed)"
    echo
    
    echo "Next Steps:"
    echo "  1. Run step 2 (Root): ./step2_root_mount_en.sh"
    echo "  2. Or use simple mode: ./ubuntu-proot.sh"
    echo
    
    echo "Note:"
    echo "  • For full functionality, step 2 (Root) is recommended"
    echo "  • proot mode has limitations"
    echo
    
    print_success "Ready for next step!"
}

# Main function
main() {
    print_header
    
    print_info "Starting Step 1: Ubuntu Chroot preparation..."
    echo
    
    # Execute steps
    step1_check_termux
    step2_check_storage
    step3_update_packages
    step4_install_tools
    step5_download_ubuntu
    step6_extract_ubuntu
    step7_setup_network
    step8_create_setup_script
    
    # Cleanup and result
    cleanup
    show_result
}

# Run program
main "$@"
