#!/usr/bin/env bash

# Arch-specific official packages are installed as root with pacman. AUR
# packages are kept separate so the trust and build seam remains visible and
# all builds happen as the target user. Applications and CLIs used on both
# Arch and macOS live in the repository-level packages.yaml manifest.

BOOTSTRAP_PACKAGES=(
    base-devel
    ca-certificates
    curl
    git
    go-yq
    sudo
    zsh
)

BASE_SYSTEM_PACKAGES=(
    base
    btrfs-progs
    cronie
    efibootmgr
    inetutils
    iptables
    linux
    linux-firmware
    linux-headers
    man-db
    man-pages
    nano
    openssh
    pacman-contrib
    procps-ng
    unrar
    unzip
    vim
    xdg-user-dirs
    xdg-utils
    zip
    zram-generator
)

AMD_GRAPHICS_PACKAGES=(
    amd-ucode
    lact
    lib32-mesa
    lib32-vulkan-radeon
    libva-utils
    mesa
    mesa-utils
    rocm-smi-lib
    rocminfo
    vulkan-radeon
    xf86-video-amdgpu
)

DESKTOP_FOUNDATION_PACKAGES=(
    avahi
    bluez
    bluez-utils
    brightnessctl
    cups
    ddcutil
    greetd
    greetd-tuigreet
    gst-plugin-pipewire
    iwd
    libnotify
    networkmanager
    nss-mdns
    pipewire
    pipewire-alsa
    pipewire-jack
    pipewire-pulse
    system-config-printer
    wireplumber
)

HYPRLAND_PACKAGES=(
    adw-gtk-theme
    dconf
    fcitx5
    fcitx5-chinese-addons
    fcitx5-configtool
    fcitx5-gtk
    fcitx5-material-color
    fcitx5-qt
    fcitx5-rime
    fortune-mod
    gnome-keyring
    grim
    hyprland
    kvantum
    kvantum-qt5
    noctalia
    nwg-look
    qt5-wayland
    qt5ct
    qt6-wayland
    qt6ct
    slurp
    swappy
    uwsm
    wl-clipboard
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
)

GUI_APPLICATION_PACKAGES=(
    android-file-transfer
    distroshelf
    filezilla
    gnome-calculator
    gvfs-gphoto2
    gvfs-smb
    loupe
    mtpfs
    nautilus
    openrgb
    steam
    virt-manager
    virt-viewer
    zathura
    zathura-cb
    zathura-djvu
    zathura-pdf-mupdf
)

CLI_PACKAGES=(
    bind
    distrobox
    gphoto2
    htop
    less
    rust
    ueberzugpp
)

VIRTUALIZATION_PACKAGES=(
    dnsmasq
    guestfs-tools
    libvirt
    qemu-desktop
    swtpm
)

GAMING_PACKAGES=(
    gamescope
    goverlay
    lib32-mangohud
    mangohud
)

SYSTEM_UTILITY_PACKAGES=(
    liquidctl
    smartmontools
    tuned
    v4l2loopback-dkms
)

AUR_PACKAGES=(
    fladder-git
    heroic-games-launcher-bin
    protonplus
    rime-ice-git
    trashy
    wayscriber-bin
    winboat-bin
)

OFFICIAL_PACKAGES=(
    "${BASE_SYSTEM_PACKAGES[@]}"
    "${AMD_GRAPHICS_PACKAGES[@]}"
    "${DESKTOP_FOUNDATION_PACKAGES[@]}"
    "${HYPRLAND_PACKAGES[@]}"
    "${GUI_APPLICATION_PACKAGES[@]}"
    "${CLI_PACKAGES[@]}"
    "${VIRTUALIZATION_PACKAGES[@]}"
    "${GAMING_PACKAGES[@]}"
    "${SYSTEM_UTILITY_PACKAGES[@]}"
)

SYSTEM_SERVICES=(
    NetworkManager.service
    avahi-daemon.service
    bluetooth.service
    cronie.service
    cups.service
    docker.service
    fstrim.timer
    greetd.service
    lactd.service
    libvirtd.service
    paccache.timer
    tailscaled.service
    tuned.service
)
