#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_FIXTURE=""
DRY_RUN_OUTPUT=""
MEMORY_FIXTURE=""
POST_INSTALL_FIXTURE=""
STOW_FIXTURE=""
SHARED_ARCH_AUR_PACKAGES=()
SHARED_ARCH_OFFICIAL_PACKAGES=()

cleanup() {
    if [[ -n "$DOTFILES_FIXTURE" && -d "$DOTFILES_FIXTURE" ]]; then
        rm -rf -- "$DOTFILES_FIXTURE"
    fi
    if [[ -n "$STOW_FIXTURE" && -d "$STOW_FIXTURE" ]]; then
        rm -rf -- "$STOW_FIXTURE"
    fi
    if [[ -n "$POST_INSTALL_FIXTURE" && -d "$POST_INSTALL_FIXTURE" ]]; then
        rm -rf -- "$POST_INSTALL_FIXTURE"
    fi
    if [[ -n "$MEMORY_FIXTURE" && -d "$MEMORY_FIXTURE" ]]; then
        rm -rf -- "$MEMORY_FIXTURE"
    fi
}

trap cleanup EXIT

# shellcheck source=linux-bootstrap/lib/packages.sh
source "$SCRIPT_DIR/lib/packages.sh"
# shellcheck source=lib/shared-packages.sh
source "$SCRIPT_DIR/../lib/shared-packages.sh"

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

printf 'Checking shell syntax...\n'
for script in \
    "$SCRIPT_DIR/bootstrap.sh" \
    "$SCRIPT_DIR/fonts.sh" \
    "$SCRIPT_DIR/post-check.sh" \
    "$SCRIPT_DIR/post-install.sh" \
    "$SCRIPT_DIR/lib/"*.sh \
    "$SCRIPT_DIR/../lib/"*.sh \
    "$SCRIPT_DIR/../macos-bootstrap/install-packages.sh"; do
    bash -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
    printf 'Running ShellCheck...\n'
    shellcheck \
        "$SCRIPT_DIR/bootstrap.sh" \
        "$SCRIPT_DIR/fonts.sh" \
        "$SCRIPT_DIR/post-check.sh" \
        "$SCRIPT_DIR/post-install.sh" \
        "$SCRIPT_DIR/lib/"*.sh \
        "$SCRIPT_DIR/../lib/"*.sh \
        "$SCRIPT_DIR/../macos-bootstrap/install-packages.sh"
fi

printf 'Checking package manifest invariants...\n'
validate_shared_package_manifest
mapfile -t SHARED_ARCH_OFFICIAL_PACKAGES < <(shared_arch_pacman_packages)
mapfile -t SHARED_ARCH_AUR_PACKAGES < <(shared_arch_aur_packages)

[[ -d "$SCRIPT_DIR/../config/.config" ]] \
    || fail "public config Stow package is missing"
[[ -f "$SCRIPT_DIR/../git/.gitconfig" && -f "$SCRIPT_DIR/../git/.gitignore" ]] \
    || fail "public Git Stow package is incomplete"

git config --file "$SCRIPT_DIR/../git/.gitconfig" --list >/dev/null \
    || fail "public Git configuration is invalid"

private_git_keys="$(
    git config --file "$SCRIPT_DIR/../git/.gitconfig" --name-only --list \
        | grep -Ei '^(credential\.|includeif\.|user\.)' \
        || true
)"
[[ -z "$private_git_keys" ]] \
    || fail "public Git configuration contains private or machine-local keys: $private_git_keys"

for git_overlay in '~/.gitconfig.private' '~/.gitconfig.local'; do
    git config --file "$SCRIPT_DIR/../git/.gitconfig" --get-all include.path \
        | grep -Fxq "$git_overlay" \
        || fail "public Git configuration does not include $git_overlay"
done

STOW_FIXTURE="$(mktemp -d)"
mkdir -p "$STOW_FIXTURE/.config"
stow \
    --dir "$SCRIPT_DIR/.." \
    --target "$STOW_FIXTURE" \
    --ignore='^\.config/(aerospace|borders|karabiner|sketchybar|skhd|spacebar|yabai)(/|$)' \
    --ignore='^\.config/hypr/.*\.bak$' \
    --ignore='^\.config/zsh/\.zcompdump' \
    config git
[[ -L "$STOW_FIXTURE/.gitconfig" && -L "$STOW_FIXTURE/.gitignore" ]] \
    || fail "public Git Stow package does not deploy both global files"
[[ -L "$STOW_FIXTURE/.config/hypr" && -L "$STOW_FIXTURE/.config/noctalia" ]] \
    || fail "public config Stow package does not fold application directories"
[[ -L "$STOW_FIXTURE/.config/Kvantum" \
    && -L "$STOW_FIXTURE/.config/gtk-3.0" \
    && -L "$STOW_FIXTURE/.config/gtk-4.0" ]] \
    || fail "public config Stow package does not deploy dark toolkit configuration"

grep -Fqx 'theme=KvGnomeDark' \
    "$SCRIPT_DIR/../config/.config/Kvantum/kvantum.kvconfig" \
    || fail "Kvantum does not default to its packaged dark theme"
grep -Fqx 'gtk-theme-name=adw-gtk3-dark' \
    "$SCRIPT_DIR/../config/.config/gtk-3.0/settings.ini" \
    || fail "GTK 3 does not default to its packaged dark theme"
for gtk_version in 3.0 4.0; do
    grep -Fqx 'gtk-icon-theme-name=Adwaita' \
        "$SCRIPT_DIR/../config/.config/gtk-$gtk_version/settings.ini" \
        || fail "GTK $gtk_version does not default to high-contrast Adwaita icons"
done
grep -Fq "icon-theme='Adwaita'" "$SCRIPT_DIR/bootstrap.sh" \
    || fail "Dconf does not default desktop applications to Adwaita icons"
grep -Fqx 'mode = "dark"' "$SCRIPT_DIR/../config/.config/noctalia/config.toml" \
    || fail "Noctalia does not default to dark mode"

duplicates="$(
    printf '%s\n' \
        "${BOOTSTRAP_PACKAGES[@]}" \
        "${OFFICIAL_PACKAGES[@]}" \
        "${AUR_PACKAGES[@]}" \
        "${SHARED_ARCH_OFFICIAL_PACKAGES[@]}" \
        "${SHARED_ARCH_AUR_PACKAGES[@]}" \
        | sort \
        | uniq -d
)"
[[ -z "$duplicates" ]] || fail "duplicate package declarations: $duplicates"

forbidden="$(
    printf '%s\n' \
        "${OFFICIAL_PACKAGES[@]}" \
        "${AUR_PACKAGES[@]}" \
        "${SHARED_ARCH_OFFICIAL_PACKAGES[@]}" \
        "${SHARED_ARCH_AUR_PACKAGES[@]}" \
        | grep -E '^(sway|swaybg|swayidle|swaylock|plasma.*|kwin.*|dolphin|konsole|kate|ark|okular)$' \
        || true
)"
[[ -z "$forbidden" ]] || fail "Sway/KDE packages are intentionally excluded: $forbidden"

printf '%s\n' "${GUI_APPLICATION_PACKAGES[@]}" | grep -Fxq nautilus \
    || fail "Nautilus is missing from the GUI application packages"
printf '%s\n' "${GUI_APPLICATION_PACKAGES[@]}" | grep -Fxq loupe \
    || fail "GNOME Image Viewer is missing from the GUI application packages"
if printf '%s\n' "${GUI_APPLICATION_PACKAGES[@]}" \
    | grep -Eq '^(ristretto|thunar|thunar-volman)$'; then
    fail "Replaced Xfce desktop applications remain in the package manifest"
fi
grep -Fq 'file_manager     = "ghostty -e yazi"' \
    "$SCRIPT_DIR/../config/.config/hypr/lua/programs.lua" \
    || fail "Hyprland does not retain Yazi as its terminal file manager"
grep -Fq 'gui_file_manager = "nautilus --new-window"' \
    "$SCRIPT_DIR/../config/.config/hypr/lua/programs.lua" \
    || fail "Hyprland does not configure Nautilus as its graphical file manager"
grep -Fq 'hl.bind(modShift .. " + E", hl.dsp.exec_cmd(progs.gui_file_manager))' \
    "$SCRIPT_DIR/../config/.config/hypr/lua/keybindings.lua" \
    || fail "Hyprland does not bind Super+Shift+E to Nautilus"

printf 'Checking official package availability...\n'
if ! pacman -Si \
    "${BOOTSTRAP_PACKAGES[@]}" \
    "${OFFICIAL_PACKAGES[@]}" \
    "${SHARED_ARCH_OFFICIAL_PACKAGES[@]}" \
    >/dev/null 2>&1; then
    for package in \
        "${BOOTSTRAP_PACKAGES[@]}" \
        "${OFFICIAL_PACKAGES[@]}" \
        "${SHARED_ARCH_OFFICIAL_PACKAGES[@]}"; do
        pacman -Si "$package" >/dev/null 2>&1 \
            || fail "official package is unavailable: $package"
    done
fi

if command -v paru >/dev/null 2>&1; then
    printf 'Checking AUR package availability...\n'
    if ! paru -Si "${AUR_PACKAGES[@]}" "${SHARED_ARCH_AUR_PACKAGES[@]}" >/dev/null 2>&1; then
        for package in "${AUR_PACKAGES[@]}" "${SHARED_ARCH_AUR_PACKAGES[@]}"; do
            paru -Si "$package" >/dev/null 2>&1 \
                || fail "AUR package is unavailable: $package"
        done
    fi
else
    printf 'Skipping AUR availability checks because paru is not installed.\n'
fi

printf 'Checking the public bootstrap interface...\n'
DRY_RUN_OUTPUT="$(
    "$SCRIPT_DIR/bootstrap.sh" --user dot_bootstrap_check --dry-run
)"

for expected_path in \
    /etc/dconf/profile/user \
    /etc/dconf/db/local.d/00-dark-theme \
    /etc/zsh/zshenv \
    /.cache \
    /.local/share \
    /.local/state \
    /.cache/zsh \
    /.local/state/zsh; do
    grep -Fq "$expected_path" <<<"$DRY_RUN_OUTPUT" \
        || fail "bootstrap omits required setup path: $expected_path"
done

grep -Fq 'org.gnome.Nautilus.desktop' <<<"$DRY_RUN_OUTPUT" \
    || fail "bootstrap does not register Nautilus as the directory handler"
grep -Fq 'org.gnome.Loupe.desktop' <<<"$DRY_RUN_OUTPUT" \
    || fail "bootstrap does not register GNOME Image Viewer for images"
for memory_setting in \
    'zram-size = ram / 2' \
    'compression-algorithm = zstd' \
    'swap-priority = 100' \
    'vm.swappiness=100' \
    "option='pri=10'"; do
    grep -Fq "$memory_setting" "$SCRIPT_DIR/lib/memory.sh" \
        || fail "bootstrap omits memory setting: $memory_setting"
done
grep -Fq 'sysctl vm.swappiness' "$SCRIPT_DIR/lib/memory.sh" \
    || fail "bootstrap does not verify swappiness"
grep -Fq 'run zramctl' "$SCRIPT_DIR/lib/memory.sh" \
    || fail "bootstrap does not verify Zram"
grep -Fq 'run swapon --show' "$SCRIPT_DIR/lib/memory.sh" \
    || fail "bootstrap does not verify active swap"
if grep -Eq 'zram-size = min\(ram / 2, 16 \* 1024\)|vm\.swappiness[[:space:]]*=[[:space:]]*150' \
    "$SCRIPT_DIR/lib/memory.sh"; then
    fail "bootstrap retains superseded memory settings"
fi

MEMORY_FIXTURE="$(mktemp -d)"
printf '%s\n' \
    '# preserve zram comment' \
    '[zram0]' \
    'host-memory-limit = none' \
    'zram-size = 4096' \
    'zram-fraction = 0.25' \
    'max-zram-size = 8192' \
    'compression-algorithm = lzo' \
    'swap-priority = 50' \
    'options = discard' \
    '' \
    '[zram1]' \
    'zram-size = ram / 8' \
    >"$MEMORY_FIXTURE/zram-generator.conf"
printf '%s\n' \
    '# preserve sysctl comment' \
    'vm.dirty_ratio=15' \
    'vm.swappiness=60' \
    'vm.swappiness = 80' \
    >"$MEMORY_FIXTURE/99-memory.conf"
printf '%s\n' \
    'vm.swappiness = 150' \
    'vm.page-cluster = 0' \
    >"$MEMORY_FIXTURE/99-zram.conf"
printf '%s\n' \
    '# preserve fstab comment' \
    'UUID=root / btrfs rw 0 0' \
    'UUID=swap none swap defaults,discard,pri=5,nofail 0 0' \
    '/swapfile none swap pri=20 0 0 # preserve inline comment' \
    >"$MEMORY_FIXTURE/fstab"

(
    DRY_RUN=false
    FSTAB_PATH="$MEMORY_FIXTURE/fstab"
    LEGACY_ZRAM_SYSCTL_PATH="$MEMORY_FIXTURE/99-zram.conf"
    MEMORY_SYSCTL_PATH="$MEMORY_FIXTURE/99-memory.conf"
    ZRAM_GENERATOR_CONFIG_PATH="$MEMORY_FIXTURE/zram-generator.conf"
    source "$SCRIPT_DIR/lib/common.sh"
    source "$SCRIPT_DIR/lib/memory.sh"

    configure_zram_generator
    configure_swappiness_file
    remove_legacy_swappiness_setting
    configure_disk_swap_priority
)

for zram_setting in \
    'zram-size = ram / 2' \
    'compression-algorithm = zstd' \
    'swap-priority = 100'; do
    [[ "$(grep -Fxc "$zram_setting" "$MEMORY_FIXTURE/zram-generator.conf")" == 1 ]] \
        || fail "Zram fixture does not contain exactly one setting: $zram_setting"
done
grep -Fqx 'host-memory-limit = none' "$MEMORY_FIXTURE/zram-generator.conf" \
    || fail "Zram rewrite discarded an unrelated zram0 setting"
grep -Fqx 'zram-size = ram / 8' "$MEMORY_FIXTURE/zram-generator.conf" \
    || fail "Zram rewrite modified an unrelated device section"
if grep -Eq '^[[:space:]]*(zram-fraction|max-zram-size)[[:space:]]*=' \
    "$MEMORY_FIXTURE/zram-generator.conf"; then
    fail "Zram rewrite retains a legacy setting that overrides zram-size"
fi
[[ "$(grep -Ec '^[[:space:]]*vm\.swappiness[[:space:]]*=' \
    "$MEMORY_FIXTURE/99-memory.conf")" == 1 ]] \
    || fail "memory sysctl fixture does not contain exactly one swappiness setting"
grep -Fqx 'vm.swappiness=100' "$MEMORY_FIXTURE/99-memory.conf" \
    || fail "memory sysctl fixture does not set swappiness 100"
grep -Fqx 'vm.dirty_ratio=15' "$MEMORY_FIXTURE/99-memory.conf" \
    || fail "memory sysctl rewrite discarded an unrelated setting"
if grep -Eq '^[[:space:]]*vm\.swappiness[[:space:]]*=' \
    "$MEMORY_FIXTURE/99-zram.conf"; then
    fail "legacy Zram sysctl file retains a conflicting swappiness setting"
fi
grep -Fqx 'vm.page-cluster = 0' "$MEMORY_FIXTURE/99-zram.conf" \
    || fail "legacy sysctl cleanup discarded an unrelated setting"
grep -Fqx 'UUID=swap none swap defaults,discard,pri=10,nofail 0 0' \
    "$MEMORY_FIXTURE/fstab" \
    || fail "fstab swap partition did not receive priority 10"
grep -Fqx '/swapfile none swap pri=10 0 0 # preserve inline comment' \
    "$MEMORY_FIXTURE/fstab" \
    || fail "fstab swapfile did not preserve its source and inline comment"

memory_checksum_before="$(sha256sum "$MEMORY_FIXTURE"/*)"
(
    DRY_RUN=false
    FSTAB_PATH="$MEMORY_FIXTURE/fstab"
    LEGACY_ZRAM_SYSCTL_PATH="$MEMORY_FIXTURE/99-zram.conf"
    MEMORY_SYSCTL_PATH="$MEMORY_FIXTURE/99-memory.conf"
    ZRAM_GENERATOR_CONFIG_PATH="$MEMORY_FIXTURE/zram-generator.conf"
    source "$SCRIPT_DIR/lib/common.sh"
    source "$SCRIPT_DIR/lib/memory.sh"

    configure_zram_generator
    configure_swappiness_file
    remove_legacy_swappiness_setting
    configure_disk_swap_priority
) >/dev/null
memory_checksum_after="$(sha256sum "$MEMORY_FIXTURE"/*)"
[[ "$memory_checksum_before" == "$memory_checksum_after" ]] \
    || fail "memory configuration is not idempotent"

for tool_installer in \
    https://chatgpt.com/codex/install.sh \
    https://claude.ai/install.sh \
    https://raw.githubusercontent.com/danielmiessler/fabric/main/scripts/installer/install.sh; do
    grep -Fq "$tool_installer" <<<"$DRY_RUN_OUTPUT" \
        || fail "bootstrap omits user-tool installer: $tool_installer"
done

DOTFILES_FIXTURE="$(mktemp -d)"
mkdir -p "$DOTFILES_FIXTURE/git"
touch "$DOTFILES_FIXTURE/git/.gitconfig.private"
stow --dir "$DOTFILES_FIXTURE" --target "$STOW_FIXTURE" git
[[ -L "$STOW_FIXTURE/.gitconfig.private" ]] \
    || fail "private Git overlay cannot be Stowed alongside the public package"
"$SCRIPT_DIR/bootstrap.sh" \
    --user "${SUDO_USER:-${USER:-lichader}}" \
    --dotfiles-dir "$DOTFILES_FIXTURE" \
    --dry-run \
    >/dev/null

POST_INSTALL_FIXTURE="$(mktemp -d)"
post_install_output="$(
    HOME="$POST_INSTALL_FIXTURE" \
        "$SCRIPT_DIR/post-install.sh" --dry-run
)"
grep -Fq 'sudo tailscale up' <<<"$post_install_output" \
    || fail "post-install dry run omits the Tailscale connection"
grep -Fq 'gh auth login' <<<"$post_install_output" \
    || fail "post-install dry run omits GitHub authentication"
grep -Fq 'gh repo clone' <<<"$post_install_output" \
    || fail "post-install dry run omits the private checkout"
grep -Fq 'lichader/post-setup-config' <<<"$post_install_output" \
    || fail "post-install dry run omits the post-setup repository"
grep -Fq 'stow --dir' <<<"$post_install_output" \
    || fail "post-install dry run omits private Git deployment"

tailscale_line="$(grep -nFm1 'sudo tailscale up' <<<"$post_install_output")"
clone_line="$(grep -nFm1 'gh repo clone' <<<"$post_install_output")"
[[ "${tailscale_line%%:*}" -lt "${clone_line%%:*}" ]] \
    || fail "post-install must connect Tailscale before cloning private configuration"

printf 'Setup checks passed.\n'
