#!/bin/sh

# ============================================================
#              DEUP GAMING - ROOTFS LAUNCHER
# ============================================================
# Modified & Maintained by: DEUP GAMING
# Original project: Foxytoux / Freeroot
# Original copyright: RecodeStudios.Cloud (2024)
# ============================================================

set -eu

ROOTFS_DIR="$(pwd -P)"
MAX_RETRIES=5
DOWNLOAD_TIMEOUT=20

TMP_ARCHIVE="${TMPDIR:-/tmp}/deup-ubuntu-base-$$.tar.gz"
PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"

UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base"

PROOT_URL="https://raw.githubusercontent.com/foxytouxxx/freeroot/main"

trap 'rm -f "$TMP_ARCHIVE"' EXIT
trap 'exit 1' HUP INT TERM

# -------------------- COLORS --------------------

if [ -t 1 ]; then
    CYAN="$(printf '\033[1;36m')"
    GREEN="$(printf '\033[1;32m')"
    RED="$(printf '\033[1;31m')"
    YELLOW="$(printf '\033[1;33m')"
    WHITE="$(printf '\033[1;37m')"
    RESET="$(printf '\033[0m')"
else
    CYAN=""
    GREEN=""
    RED=""
    YELLOW=""
    WHITE=""
    RESET=""
fi

# -------------------- FUNCTIONS --------------------

banner() {
    printf '\n'
    printf '%s============================================================%s\n' "$CYAN" "$RESET"
    printf '%s                  DEUP GAMING ROOTFS%s\n' "$WHITE" "$RESET"
    printf '%s============================================================%s\n' "$CYAN" "$RESET"
    printf '%s             Modified & Maintained by DEUP GAMING%s\n' "$GREEN" "$RESET"
    printf '%s             Based on Foxytoux / Freeroot%s\n' "$YELLOW" "$RESET"
    printf '%s============================================================%s\n\n' "$CYAN" "$RESET"
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

# -------------------- START --------------------

banner

info "Checking system requirements..."

command -v wget >/dev/null 2>&1 || die "wget is not installed."
command -v tar >/dev/null 2>&1 || die "tar is not installed."

ARCH="$(uname -m)"

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

success "Architecture detected: $ARCH"

mkdir -p "$ROOTFS_DIR/usr/local/bin"

# -------------------- UBUNTU INSTALLATION --------------------

if [ ! -f "$ROOTFS_DIR/.installed" ]; then

    printf '\n%s[1/3] Installing Ubuntu 20.04 RootFS%s\n' "$WHITE" "$RESET"

    info "Downloading Ubuntu base image..."

    if ! wget \
        --tries="$MAX_RETRIES" \
        --timeout="$DOWNLOAD_TIMEOUT" \
        --no-hsts \
        -O "$TMP_ARCHIVE" \
        "${UBUNTU_URL}-${ARCH_ALT}.tar.gz"; then

        die "Ubuntu download failed."
    fi

    [ -s "$TMP_ARCHIVE" ] || die "Downloaded Ubuntu archive is empty."

    success "Ubuntu image downloaded."

    info "Extracting Ubuntu RootFS..."

    tar -xzf "$TMP_ARCHIVE" -C "$ROOTFS_DIR" \
        || die "Ubuntu extraction failed."

    success "Ubuntu RootFS extracted."

    # -------------------- DNS CONFIGURATION --------------------

    mkdir -p "$ROOTFS_DIR/etc"

    rm -f "$ROOTFS_DIR/etc/resolv.conf"

    printf 'nameserver 1.1.1.1\nnameserver 1.0.0.1\n' \
        > "$ROOTFS_DIR/etc/resolv.conf"

    success "DNS configuration completed."

else

    success "Existing Ubuntu installation detected."
    info "Skipping Ubuntu installation."

fi

# -------------------- PROOT INSTALLATION --------------------

printf '\n%s[2/3] Checking PRoot Binary%s\n' "$WHITE" "$RESET"

if [ ! -x "$PROOT_BIN" ]; then

    info "Downloading PRoot for $ARCH..."

    if ! wget \
        --tries="$MAX_RETRIES" \
        --timeout="$DOWNLOAD_TIMEOUT" \
        --no-hsts \
        -O "$PROOT_BIN" \
        "${PROOT_URL}/proot-${ARCH}"; then

        rm -f "$PROOT_BIN"
        die "PRoot download failed."
    fi

    [ -s "$PROOT_BIN" ] || die "Downloaded PRoot binary is empty."

    chmod 755 "$PROOT_BIN"

    success "PRoot installed successfully."

else

    success "PRoot is already installed."

fi

# -------------------- FINAL CHECKS --------------------

printf '\n%s[3/3] Finalizing Installation%s\n' "$WHITE" "$RESET"

[ -d "$ROOTFS_DIR/etc" ] || die "Ubuntu RootFS is incomplete."

mkdir -p "$ROOTFS_DIR/root"

if [ ! -f "$ROOTFS_DIR/.installed" ]; then
    touch "$ROOTFS_DIR/.installed"
fi

success "Installation completed successfully."

# -------------------- LAUNCH --------------------

printf '\n'
printf '%s============================================================%s\n' "$GREEN" "$RESET"
printf '%s                 ROOTFS READY TO LAUNCH%s\n' "$WHITE" "$RESET"
printf '%s============================================================%s\n' "$GREEN" "$RESET"
printf '\n'
info "Starting Ubuntu environment..."
printf '\n'

exec "$PROOT_BIN" \
    --rootfs="$ROOTFS_DIR" \
    -0 \
    -w "/root" \
    -b /dev \
    -b /sys \
    -b /proc \
    -b /etc/resolv.conf \
    --kill-on-exit
