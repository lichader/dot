#!/usr/bin/env bash

set -euo pipefail

APPLE_FONTS_PACKAGE="apple-fonts"
PINGFANG_PACKAGE="otf-apple-pingfang"
BASE_FONT_PACKAGES=(
    inter-font
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    ttf-jetbrains-mono-nerd
    ttf-sarasa-gothic
)

# Apple replaced the SF Pro and SF Compact files behind its stable download
# URLs in June 2026. These hashes are used only when the current AUR recipe
# still contains the previous hashes.
OLD_SF_PRO_SHA256="5b4b19922a41b6b76e227934a2871b1405d7d6acb467eca4db153215f0d6c78b"
OLD_SF_COMPACT_SHA256="4567aae0616dd35afc34bad6bef547e72fd1e65845305a33973064518d1d5348"
CURRENT_SF_PRO_SHA256="6311a4f0843a4d2e616a0b05c77512d31d2ea950459cf526cdb5b90996a0794f"
CURRENT_SF_COMPACT_SHA256="fe517a5184be290e66fe89b8b4b6ea18548fced1ae1539499a71265e3317249f"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Required command not found: $1" >&2
        exit 1
    fi
}

install_packages_if_missing() {
    local missing_packages=()
    local package

    for package in "$@"; do
        if ! pacman -Q "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done

    if ((${#missing_packages[@]} == 0)); then
        echo "Font package dependencies are already installed."
        return 0
    fi

    paru -S --needed --noconfirm --skipreview --noinstalldebug "${missing_packages[@]}"
}

install_apple_fonts_from_patched_aur() {
    local build_dir
    local build_status=0
    build_dir="$(mktemp -d)"

    echo "Retrying apple-fonts with the verified June 2026 Apple CDN hashes..."
    if ! git clone --depth 1 https://aur.archlinux.org/apple-fonts.git "$build_dir/apple-fonts"; then
        rm -rf -- "$build_dir"
        return 1
    fi

    local pkgbuild="$build_dir/apple-fonts/PKGBUILD"

    if ! grep -Fq "https://devimages-cdn.apple.com/design/resources/download/" "$pkgbuild"; then
        echo "Refusing to patch apple-fonts: its sources are no longer Apple's official CDN." >&2
        rm -rf -- "$build_dir"
        return 1
    fi

    if ! grep -Fq "$OLD_SF_PRO_SHA256" "$pkgbuild" \
        || ! grep -Fq "$OLD_SF_COMPACT_SHA256" "$pkgbuild"; then
        echo "Refusing to patch apple-fonts: the AUR recipe no longer matches the reviewed version." >&2
        rm -rf -- "$build_dir"
        return 1
    fi

    sed -i \
        -e "s/$OLD_SF_PRO_SHA256/$CURRENT_SF_PRO_SHA256/" \
        -e "s/$OLD_SF_COMPACT_SHA256/$CURRENT_SF_COMPACT_SHA256/" \
        "$pkgbuild"

    (
        cd "$build_dir/apple-fonts"
        makepkg --syncdeps --install --noconfirm --needed
    ) || build_status=$?

    rm -rf -- "$build_dir"
    return "$build_status"
}

verify_font() {
    local requested_family="$1"
    local expected_family="$2"
    local actual_family

    actual_family="$(fc-match --format='%{family[0]}' "$requested_family")"
    if [[ "$actual_family" != "$expected_family" ]]; then
        echo "Font verification failed: $requested_family resolved to $actual_family, expected $expected_family." >&2
        exit 1
    fi

    echo "$requested_family -> $actual_family"
}

if [[ ! -r /etc/arch-release ]]; then
    echo "This setup script supports Arch Linux only." >&2
    exit 1
fi

require_command paru
require_command git
require_command makepkg
require_command fc-cache
require_command fc-match

echo "Installing font packages..."

install_packages_if_missing "${BASE_FONT_PACKAGES[@]}"
install_packages_if_missing "$PINGFANG_PACKAGE"

if ! pacman -Q "$APPLE_FONTS_PACKAGE" >/dev/null 2>&1; then
    if ! paru -S --needed --noconfirm --skipreview --noinstalldebug "$APPLE_FONTS_PACKAGE"; then
        install_apple_fonts_from_patched_aur
    fi
else
    echo "$APPLE_FONTS_PACKAGE is already installed."
fi

echo "Refreshing the Fontconfig cache..."
fc-cache -f

echo "Verifying installed font families..."
verify_font "SF Pro Text" "SF Pro Text"
verify_font "SF Mono" "SF Mono"
verify_font "New York" "New York"
verify_font "PingFang SC" "PingFang SC"
verify_font "PingFang TC" "PingFang TC"
verify_font "PingFang HK" "PingFang HK"
verify_font "PingFang MO" "PingFang MO"
verify_font "JetBrainsMono Nerd Font" "JetBrainsMono Nerd Font"

if [[ -f "$HOME/.config/fontconfig/fonts.conf" ]]; then
    echo "Verifying active generic and locale-specific mappings..."
    verify_font "sans-serif" "SF Pro Text"
    verify_font "serif" "New York"
    verify_font "monospace" "SF Mono"
    verify_font ":lang=zh-cn:family=sans-serif" "PingFang SC"
    verify_font ":lang=zh-tw:family=sans-serif" "PingFang TC"
else
    echo "Font packages are installed, but ~/.config/fontconfig/fonts.conf is not active."
    echo "Stow the repository's config directory, then run: fc-cache -f"
fi

echo "Font setup complete."
