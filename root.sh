#!/bin/sh

# ============================================================
#                  DEUP GAMING ROOTFS
# ============================================================
# Modified & Maintained by: DEUP GAMING
# Original project: Foxytoux / Freeroot
# Original copyright: RecodeStudios.Cloud (2024)
# ============================================================

set -eu

ROOTFS_DIR="$(pwd -P)"
MAX_RETRIES=5
DOWNLOAD_TIMEOUT=20

ARCH="$(uname -m)"

PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"
PROOT_TMP="${PROOT_BIN}.download"

TMP_ARCHIVE="${TMPDIR:-/tmp}/deup-rootfs-$$.tar.gz"

PROOT_URL="https://raw.githubusercontent.com/foxytouxxx/freeroot/main"
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base"

trap 'rm -f "$TMP_ARCHIVE" "$PROOT_TMP"' EXIT
trap 'exit 1' HUP INT TERM

# ============================================================
# COLORS
# ============================================================

CYAN="$(printf '\033[1;36m')"
GREEN="$(printf '\033[1;32m')"
RED="$(printf '\033[1;31m')"
YELLOW="$(printf '\033[1;33m')"
WHITE="$(printf '\033[1;37m')"
RESET="$(printf '\033[0m')"

# ============================================================
# FUNCTIONS
# ============================================================

banner() {
    printf '\n'
    printf '%s  ╔══════════════════════════════════════════════════╗%s\n' "$CYAN" "$RESET"
    printf '%s  ║                                                  ║%s\n' "$CYAN" "$RESET"
    printf '%s  ║              DEUP GAMING ROOTFS                 ║%s\n' "$WHITE" "$RESET"
    printf '%s  ║                                                  ║%s\n' "$CYAN" "$RESET"
    printf '%s  ║          UBUNTU ENVIRONMENT INSTALLER            ║%s\n' "$GREEN" "$RESET"
    printf '%s  ║                                                  ║%s\n' "$CYAN" "$RESET"
    printf '%s  ╚══════════════════════════════════════════════════╝%s\n' "$CYAN" "$RESET"
    printf '\n'
    printf '        %sModified & Maintained by DEUP GAMING%s\n' "$GREEN" "$RESET"
    printf '        %sOriginal project: Foxytoux / Freeroot%s\n\n' "$YELLOW" "$RESET"
}

info() {
    printf '%s[INFO]%s %s\n' "$CYAN" "$RESET" "$1"
}

success() {
    printf '%s[  OK]%s %s\n' "$GREEN" "$RESET" "$1"
}

warning() {
    printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$1"
}

error() {
    printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$1" >&2
}

die() {
    error "$1"
    exit 1
}

# ============================================================
# START INSTALLER
# ============================================================

if [ -t 1 ]; then
    clear 2>/dev/null || true
fi

banner

info "Checking system requirements..."

command -v wget >/dev/null 2>&1 || die "wget is not installed."
command -v tar >/dev/null 2>&1 || die "tar is not installed."

case "$ARCH" in
    x86_64)
        ARCH_ALT="amd64"
        ;;
    aarch64)
        ARCH_ALT="arm64"
        ;;
    *)
        die "Unsupported CPU architecture: $ARCH"
        ;;
esac

success "CPU Architecture: $ARCH"

mkdir -p "$ROOTFS_DIR/usr/local/bin"

# ============================================================
# UBUNTU INSTALLATION OPTION
# ============================================================

if [ ! -f "$ROOTFS_DIR/.installed" ]; then

    printf '\n'
    printf '%s  ╔══════════════════════════════════════════════╗%s\n' "$CYAN" "$RESET"
    printf '%s  ║             UBUNTU INSTALLATION              ║%s\n' "$WHITE" "$RESET"
    printf '%s  ╚══════════════════════════════════════════════╝%s\n' "$CYAN" "$RESET"
    printf '\n'

    printf '%s  Do you want to install Ubuntu 20.04? %s[Y/n]%s: ' "$WHITE" "$GREEN" "$RESET"

    read -r install_ubuntu || install_ubuntu=""

    case "$install_ubuntu" in

        [yY]|[yY][eE][sS]|"")

            printf '\n'
            info "Downloading Ubuntu 20.04..."

            if ! wget \
                --tries="$MAX_RETRIES" \
                --timeout="$DOWNLOAD_TIMEOUT" \
                --no-hsts \
                -O "$TMP_ARCHIVE" \
                "${UBUNTU_URL}-${ARCH_ALT}.tar.gz"; then

                die "Ubuntu download failed."
            fi

            [ -s "$TMP_ARCHIVE" ] || die "Ubuntu archive is empty."

            success "Ubuntu downloaded successfully."

            info "Extracting Ubuntu RootFS..."

            tar -xzf "$TMP_ARCHIVE" -C "$ROOTFS_DIR" \
                || die "Ubuntu extraction failed."

            success "Ubuntu extraction completed."

            ;;

        [nN]|[nN][oO])

            warning "Ubuntu installation skipped."

            if [ ! -d "$ROOTFS_DIR/etc" ]; then
                die "No existing Ubuntu RootFS found. Run the installer again and select YES."
            fi

            ;;

        *)

            die "Invalid option. Please select YES or NO."

            ;;

    esac

else

    success "Existing Ubuntu installation detected."
    info "Skipping Ubuntu download."

fi

# ============================================================
# ROOTFS DIRECTORY CHECK
# ============================================================

[ -d "$ROOTFS_DIR/etc" ] || die "Ubuntu RootFS is missing."

mkdir -p "$ROOTFS_DIR/root"
mkdir -p "$ROOTFS_DIR/usr/local/bin"

# ============================================================
# PROOT INSTALLATION
# ============================================================

printf '\n'
info "Checking PRoot installation..."

if [ ! -x "$PROOT_BIN" ]; then

    info "Downloading PRoot for $ARCH..."

    if ! wget \
        --tries="$MAX_RETRIES" \
        --timeout="$DOWNLOAD_TIMEOUT" \
        --no-hsts \
        -O "$PROOT_TMP" \
        "${PROOT_URL}/proot-${ARCH}"; then

        die "PRoot download failed."
    fi

    [ -s "$PROOT_TMP" ] || die "PRoot binary is empty."

    chmod 755 "$PROOT_TMP"

    mv "$PROOT_TMP" "$PROOT_BIN"

    success "PRoot installed successfully."

else

    success "PRoot already installed."

fi

# ============================================================
# DNS CONFIGURATION
# ============================================================

if [ ! -f "$ROOTFS_DIR/.installed" ]; then

    info "Configuring DNS..."

    rm -f "$ROOTFS_DIR/etc/resolv.conf"

    printf 'nameserver 1.1.1.1\nnameserver 1.0.0.1\n' \
        > "$ROOTFS_DIR/etc/resolv.conf"

    touch "$ROOTFS_DIR/.installed"

    success "DNS configured successfully."

fi

# ============================================================
# INSTALLATION COMPLETED
# ============================================================

printf '\n'
printf '%s  ╔══════════════════════════════════════════════════╗%s\n' "$GREEN" "$RESET"
printf '%s  ║                                                  ║%s\n' "$GREEN" "$RESET"
printf '%s  ║              INSTALLATION SUCCESS               ║%s\n' "$WHITE" "$RESET"
printf '%s  ║                                                  ║%s\n' "$GREEN" "$RESET"
printf '%s  ║              DEUP GAMING ROOTFS                 ║%s\n' "$CYAN" "$RESET"
printf '%s  ║                                                  ║%s\n' "$GREEN" "$RESET"
printf '%s  ╚══════════════════════════════════════════════════╝%s\n' "$GREEN" "$RESET"

printf '\n'
success "Ubuntu environment is ready!"
info "Launching terminal..."
printf '\n'

# ============================================================
# LAUNCH UBUNTU
# ============================================================

exec "$PROOT_BIN" \
    --rootfs="$ROOTFS_DIR" \
    -0 \
    -w "/root" \
    -b /dev \
    -b /sys \
    -b /proc \
    -b /etc/resolv.conf \
    --kill-on-exit
