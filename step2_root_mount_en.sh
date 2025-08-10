#!/system/bin/sh

# Ubuntu Chroot Installation - Step 2 (Root Mount)
# Version: Ubuntu 24.04 LTS (Noble Numbat)
# Environment: Root Access Required

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CHROOT_DIR="/data/data/com.termux/files/home/ubuntu-chroot"
TERMUX_HOME="/data/data/com.termux/files/home"
TOTAL_STEPS=8
INSTALL_OPTIONAL=false

# Display functions
print_header() {
    clear
    echo "Ubuntu Chroot - Step 2 (Root Mount)"
    echo "==================================="
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
    
    if [ "$required" = "Essential" ]; then
        req_text="${RED}[Essential]${NC}"
    elif [ "$required" = "Recommended" ]; then
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

# Check root access
check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_error "This script requires root access!"
        print_info "Please run with:"
        echo "  su -c 'bash step2_root_mount_en.sh'"
        exit 1
    fi
    
    print_success "Root access verified"
}

# Check Ubuntu exists
check_ubuntu_exists() {
    if [ ! -d "$CHROOT_DIR" ]; then
        print_error "Ubuntu Chroot not found!"
        print_info "Please run step 1 first: ./step1_termux_setup_en.sh"
        exit 1
    fi
    
    print_success "Ubuntu Chroot found"
}

# Ask user for optional install
ask_optional_install() {
    echo
    print_info "Do you want to install optional components (GPU, Audio, Advanced Network)?"
    echo -e "${YELLOW}y/n [default: n]:${NC} \c"
    read answer
    
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        INSTALL_OPTIONAL=true
        print_success "Full installation selected"
    else
        print_info "Essential installation selected"
    fi
}

# Step 1: Check prerequisites
step1_check_prerequisites() {
    print_header
    print_priority "High" "1" "Check prerequisites" "Essential"
    show_progress 1 $TOTAL_STEPS "Checking system"
    
    check_root
    check_ubuntu_exists
    
    print_success "All prerequisites ready"
    sleep 1
}

# Step 2-4: Essential mounts
step2_mount_essential() {
    print_priority "Medium" "2-4" "Essential mounts" "Recommended"
    show_progress 4 $TOTAL_STEPS "Mounting filesystems"
    
    # Create essential directories
    mkdir -p "$CHROOT_DIR"/{dev,proc,sys,tmp,sdcard}
    
    print_info "Mounting /dev..."
    mount --bind /dev "$CHROOT_DIR/dev" 2>/dev/null || true
    
    print_info "Mounting /proc..."
    mount -t proc proc "$CHROOT_DIR/proc" 2>/dev/null || true
    
    print_info "Mounting /sys..."
    mount -t sysfs sysfs "$CHROOT_DIR/sys" 2>/dev/null || true
    
    print_info "Mounting /tmp..."
    mount -t tmpfs tmpfs "$CHROOT_DIR/tmp" 2>/dev/null || true
    
    print_success "Essential mounts completed"
    sleep 1
}

# Step 5-7: Optional mounts
step5_mount_optional() {
    if [ "$INSTALL_OPTIONAL" != true ]; then
        print_priority "Low" "5-7" "Optional mounts" "Optional"
        show_progress 7 $TOTAL_STEPS "Skipped"
        print_info "Optional mounts skipped"
        return
    fi
    
    print_priority "Low" "5-7" "Optional mounts" "Optional"
    show_progress 7 $TOTAL_STEPS "Mounting hardware"
    
    # Mount GPU (DRI)
    if [ -d "/dev/dri" ]; then
        print_info "Mounting GPU (DRI)..."
        mkdir -p "$CHROOT_DIR/dev/dri"
        mount --bind /dev/dri "$CHROOT_DIR/dev/dri" 2>/dev/null || true
    fi
    
    # Mount GPU (KGSL - Adreno)
    if [ -d "/dev/kgsl" ]; then
        print_info "Mounting GPU (KGSL)..."
        mkdir -p "$CHROOT_DIR/dev/kgsl"
        mount --bind /dev/kgsl "$CHROOT_DIR/dev/kgsl" 2>/dev/null || true
    fi
    
    # Mount Audio
    if [ -d "/dev/snd" ]; then
        print_info "Mounting Audio..."
        mkdir -p "$CHROOT_DIR/dev/snd"
        mount --bind /dev/snd "$CHROOT_DIR/dev/snd" 2>/dev/null || true
    fi
    
    # Mount Network interfaces
    if [ -d "/sys/class/net" ]; then
        print_info "Mounting Network interfaces..."
        mkdir -p "$CHROOT_DIR/sys/class/net"
        mount --bind /sys/class/net "$CHROOT_DIR/sys/class/net" 2>/dev/null || true
    fi
    
    # Mount SDCard
    if [ -d "/sdcard" ]; then
        print_info "Mounting SDCard..."
        mkdir -p "$CHROOT_DIR/sdcard"
        mount --bind /sdcard "$CHROOT_DIR/sdcard" 2>/dev/null || true
    fi
    
    print_success "Optional mounts completed"
    sleep 1
}

# Step 8: Setup and launch
step8_setup_and_launch() {
    print_priority "High" "8" "Setup and launch Ubuntu" "Essential"
    show_progress 8 $TOTAL_STEPS "Final setup"
    
    # Run initial setup (first time only)
    if [ ! -f "$CHROOT_DIR/root/.setup-complete" ]; then
        print_info "Running initial Ubuntu setup..."
        chroot "$CHROOT_DIR" /root/setup-chroot.sh
        touch "$CHROOT_DIR/root/.setup-complete"
        print_success "Initial setup completed"
    else
        print_info "Setup already completed"
    fi
    
    # Create full launcher script
    cat > "$TERMUX_HOME/ubuntu-full.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

CHROOT_DIR="$HOME/ubuntu-chroot"

# Check root access
if ! command -v su >/dev/null 2>&1 || ! su -c 'id' >/dev/null 2>&1; then
    echo "Error: Root access not available!"
    echo "Use ubuntu-proot.sh instead"
    exit 1
fi

if [ ! -d "$CHROOT_DIR" ]; then
    echo "Error: Ubuntu not found!"
    exit 1
fi

echo "Starting Ubuntu 24.04 (full chroot mode)..."

# Run root mount script
su -c "bash $HOME/step2_root_mount_en.sh --launch-only"
EOF
    
    chmod +x "$TERMUX_HOME/ubuntu-full.sh"
    
    # Create unmount script
    cat > "$TERMUX_HOME/ubuntu-unmount.sh" << EOF
#!/system/bin/sh

CHROOT_DIR="/data/data/com.termux/files/home/ubuntu-chroot"

if [ "\$(id -u)" != "0" ]; then
    echo "Run with root: su -c 'bash ubuntu-unmount.sh'"
    exit 1
fi

echo "Unmounting Ubuntu..."

umount "\$CHROOT_DIR/sdcard" 2>/dev/null || true
umount "\$CHROOT_DIR/sys/class/net" 2>/dev/null || true
umount "\$CHROOT_DIR/dev/snd" 2>/dev/null || true
umount "\$CHROOT_DIR/dev/kgsl" 2>/dev/null || true
umount "\$CHROOT_DIR/dev/dri" 2>/dev/null || true
umount "\$CHROOT_DIR/tmp" 2>/dev/null || true
umount "\$CHROOT_DIR/sys" 2>/dev/null || true
umount "\$CHROOT_DIR/proc" 2>/dev/null || true
umount "\$CHROOT_DIR/dev" 2>/dev/null || true

echo "Ubuntu unmounted successfully"
EOF
    
    chmod +x "$TERMUX_HOME/ubuntu-unmount.sh"
    
    # Add alias
    if ! grep -q "alias ubuntu=" "$TERMUX_HOME/.bashrc" 2>/dev/null; then
        echo "alias ubuntu='$TERMUX_HOME/ubuntu-full.sh'" >> "$TERMUX_HOME/.bashrc"
    fi
    
    print_success "Launch scripts created"
    sleep 1
}

# Launch Ubuntu
launch_ubuntu() {
    print_info "Entering Ubuntu 24.04..."
    echo
    
    # Set environment variables
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    export TERM="xterm-256color"
    export HOME="/root"
    
    # Enter chroot
    chroot "$CHROOT_DIR" /bin/bash -l
}

# Show final result
show_final_result() {
    print_header
    echo "Installation Completed Successfully!"
    echo "==================================="
    echo
    
    print_success "Ubuntu 24.04 Chroot with full access is ready!"
    echo
    
    echo "Installation Info:"
    echo "  • Version: Ubuntu 24.04 LTS (Noble)"
    echo "  • Path: $CHROOT_DIR"
    echo "  • Mode: Full chroot (with Root)"
    echo "  • User: user (password: ubuntu)"
    echo "  • Root: root (password: ubuntu)"
    echo
    
    echo "Launch Commands:"
    echo "  • Start Ubuntu: ubuntu"
    echo "  • Or: bash $TERMUX_HOME/ubuntu-full.sh"
    echo "  • Unmount: su -c 'bash ubuntu-unmount.sh'"
    echo
    
    echo "Installation Summary:"
    echo "  • Essential mounts: Complete"
    echo "  • Optional mounts: $([ "$INSTALL_OPTIONAL" = true ] && echo "Complete" || echo "Skipped")"
    echo "  • Hardware access: $([ "$INSTALL_OPTIONAL" = true ] && echo "Enabled" || echo "Disabled")"
    echo
    
    print_warning "To activate alias, restart Termux terminal"
    echo
    print_success "Ubuntu in your pocket!"
}

# Main function
main() {
    # Check launch-only argument
    if [ "$1" = "--launch-only" ]; then
        step2_mount_essential
        if [ "$INSTALL_OPTIONAL" = true ]; then
            step5_mount_optional
        fi
        launch_ubuntu
        return
    fi
    
    print_header
    
    print_info "Starting Step 2: Mount and launch Ubuntu..."
    echo
    
    # Ask user
    ask_optional_install
    
    echo
    print_info "Starting mount process..."
    sleep 2
    
    # Execute steps
    step1_check_prerequisites
    step2_mount_essential
    step5_mount_optional
    step8_setup_and_launch
    
    # Show result
    show_final_result
    
    echo
    print_info "Do you want to enter Ubuntu now? (y/n)"
    read answer
    
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        launch_ubuntu
    else
        print_info "Use 'ubuntu' command to enter later"
    fi
}

# Run program
main "$@"
