#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=linux-bootstrap/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=linux-bootstrap/lib/memory.sh
source "$SCRIPT_DIR/lib/memory.sh"
# shellcheck source=linux-bootstrap/lib/packages.sh
source "$SCRIPT_DIR/lib/packages.sh"
# shellcheck source=lib/shared-packages.sh
source "$REPO_ROOT/lib/shared-packages.sh"

DRY_RUN=false
TARGET_USER="${SUDO_USER:-}"
TARGET_HOME=""
TARGET_GROUP=""
DOTFILES_ROOT=""
TEMP_SUDOERS=""
PARU_BUILD_DIR=""

usage() {
    cat <<'EOF'
Usage: linux-bootstrap/bootstrap.sh [--user USERNAME] [--dotfiles-dir PATH] [--dry-run]

Bootstrap a minimal Arch installation into this Hyprland workstation.

Options:
  --user USERNAME     Existing or new daily user to configure
  --dotfiles-dir PATH Optional checkout containing private Git configuration
  --dry-run           Print mutations without performing them
  -h, --help          Show this help

Run as root from arch-chroot. If USERNAME does not exist, the bootstrap creates
it and prompts once for its login password.
EOF
}

parse_arguments() {
    while (($# > 0)); do
        case "$1" in
            --user)
                (($# >= 2)) || die "--user requires a username."
                TARGET_USER="$2"
                shift 2
                ;;
            --dotfiles-dir)
                (($# >= 2)) || die "--dotfiles-dir requires a path."
                DOTFILES_ROOT="$(realpath -m -- "$2")"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            *)
                die "Unknown argument: $1"
                ;;
        esac
    done
}

cleanup() {
    if [[ -n "$TEMP_SUDOERS" && -f "$TEMP_SUDOERS" ]]; then
        rm -f "$TEMP_SUDOERS"
    fi

    if [[ -n "$PARU_BUILD_DIR" && -d "$PARU_BUILD_DIR" ]]; then
        rm -rf -- "$PARU_BUILD_DIR"
    fi
}

trap cleanup EXIT

infer_target_user() {
    local users=()

    if [[ -n "$TARGET_USER" && "$TARGET_USER" != root ]]; then
        return 0
    fi

    mapfile -t users < <(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 { print $1 }')
    if ((${#users[@]} == 1)); then
        TARGET_USER="${users[0]}"
        return 0
    fi

    die "Pass the daily account explicitly, for example: --user lichader"
}

validate_dotfiles_source() {
    [[ -n "$DOTFILES_ROOT" ]] || return 0
    [[ -d "$DOTFILES_ROOT" ]] \
        || die "Dotfiles directory does not exist: $DOTFILES_ROOT"

    [[ -d "$DOTFILES_ROOT/git" ]] \
        || die "Dotfiles directory is missing the 'git' Stow package: $DOTFILES_ROOT"
}

enable_multilib() {
    log "Enabling the multilib repository"

    if grep -Eq '^[[:space:]]*\[multilib\]' /etc/pacman.conf; then
        printf '  multilib is already enabled.\n'
        return 0
    fi

    grep -Eq '^[[:space:]]*#\[multilib\]' /etc/pacman.conf \
        || die "Could not find the commented multilib section in /etc/pacman.conf."

    run sed -i \
        '/^[[:space:]]*#\[multilib\]/,/^[[:space:]]*#Include = \/etc\/pacman.d\/mirrorlist/ s/^[[:space:]]*#//' \
        /etc/pacman.conf
}

install_bootstrap_packages() {
    log "Updating Arch and installing the bootstrap environment"
    run pacman -Syu --needed --noconfirm "${BOOTSTRAP_PACKAGES[@]}"
}

configure_target_user() {
    local created=false

    [[ "$TARGET_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] \
        || die "Invalid target username: $TARGET_USER"

    log "Configuring daily user $TARGET_USER"

    if ! id "$TARGET_USER" >/dev/null 2>&1; then
        run useradd --create-home --groups wheel --shell /bin/zsh "$TARGET_USER"
        created=true
    else
        run usermod --append --groups wheel --shell /bin/zsh "$TARGET_USER"
    fi

    if [[ "$DRY_RUN" == true && "$created" == true ]]; then
        TARGET_HOME="/home/$TARGET_USER"
        TARGET_GROUP="$TARGET_USER"
    else
        TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
        TARGET_GROUP="$(id -gn "$TARGET_USER")"
    fi

    [[ -n "$TARGET_HOME" && "$TARGET_HOME" != / ]] \
        || die "Could not determine a safe home directory for $TARGET_USER."

    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME"

    if [[ "$DRY_RUN" != true ]] \
        && ! passwd --status "$TARGET_USER" | awk '{exit ($2 == "P" ? 0 : 1)}'; then
        log "Set the login password for $TARGET_USER"
        passwd "$TARGET_USER"
    fi

    # A repository cloned as root beneath the new user's home must become
    # writable by that user before Stow and future Git operations can use it.
    if [[ "$REPO_ROOT/" == "$TARGET_HOME/"* ]]; then
        run chown -R "$TARGET_USER:$TARGET_GROUP" "$REPO_ROOT"
    fi

    if [[ -n "$DOTFILES_ROOT" \
        && "$DOTFILES_ROOT" != "$REPO_ROOT" \
        && "$DOTFILES_ROOT/" == "$TARGET_HOME/"* ]]; then
        run chown -R "$TARGET_USER:$TARGET_GROUP" "$DOTFILES_ROOT"
    fi
}

configure_sudo() {
    local wheel_rule='%wheel ALL=(ALL:ALL) ALL'
    local bootstrap_rule="$TARGET_USER ALL=(root) NOPASSWD: /usr/bin/pacman"

    log "Configuring sudo"
    install_text_file /etc/sudoers.d/10-wheel 0440 "$wheel_rule"

    if [[ "$DRY_RUN" != true ]]; then
        visudo --check --file /etc/sudoers.d/10-wheel >/dev/null
    fi

    if [[ "$DRY_RUN" == true ]]; then
        printf '  + install temporary pacman sudo rule for %s\n' "$TARGET_USER"
        return 0
    fi

    TEMP_SUDOERS="/etc/sudoers.d/99-dotfiles-bootstrap-$$"
    printf '%s\n' "$bootstrap_rule" >"$TEMP_SUDOERS"
    chmod 0440 "$TEMP_SUDOERS"
    visudo --check --file "$TEMP_SUDOERS" >/dev/null
}

install_paru() {
    log "Installing the Paru AUR helper"

    if command -v paru >/dev/null 2>&1; then
        printf '  paru is already installed.\n'
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        printf '  + build and install paru from the AUR as %s\n' "$TARGET_USER"
        return 0
    fi

    PARU_BUILD_DIR="$(mktemp -d /var/tmp/paru-bootstrap.XXXXXX)"
    chown "$TARGET_USER:$TARGET_GROUP" "$PARU_BUILD_DIR"
    as_target_user git clone --depth 1 https://aur.archlinux.org/paru.git "$PARU_BUILD_DIR/paru"
    as_target_shell "cd '$PARU_BUILD_DIR/paru' && makepkg --syncdeps --install --noconfirm --needed"
    rm -rf -- "$PARU_BUILD_DIR"
    PARU_BUILD_DIR=""
}

install_workstation_packages() {
    local shared_aur_packages=()
    local shared_official_packages=()

    validate_shared_package_manifest
    mapfile -t shared_official_packages < <(shared_arch_pacman_packages)
    mapfile -t shared_aur_packages < <(shared_arch_aur_packages)

    log "Installing official workstation packages"
    pacman_install "${OFFICIAL_PACKAGES[@]}" "${shared_official_packages[@]}"

    log "Installing configured workstation packages from the AUR"
    paru_install "${AUR_PACKAGES[@]}" "${shared_aur_packages[@]}"
}

configure_system() {
    local service
    local dconf_dark_theme
    local dconf_profile
    local zshenv
    local networkmanager_iwd
    local greetd_config
    local greetd_pam

    log "Configuring system files"

    zshenv='if [[ -z "$XDG_CONFIG_HOME" ]]; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi'
    install_text_file /etc/zsh/zshenv 0644 "$zshenv"

    dconf_profile='user-db:user
system-db:local'
    install_text_file /etc/dconf/profile/user 0644 "$dconf_profile"

    dconf_dark_theme="[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='adw-gtk3-dark'
icon-theme='Adwaita'"
    install_text_file /etc/dconf/db/local.d/00-dark-theme 0644 "$dconf_dark_theme"
    run dconf update

    networkmanager_iwd='[device]
wifi.backend=iwd'
    install_text_file /etc/NetworkManager/conf.d/wifi_backend.conf 0644 "$networkmanager_iwd"

    greetd_config='[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-user-session --sessions /usr/share/wayland-sessions"
user = "greeter"'
    install_text_file /etc/greetd/config.toml 0644 "$greetd_config"
    ensure_directory greeter greeter 0755 /var/cache/tuigreet

    greetd_pam='#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so

account    include      system-local-login

session    include      system-local-login
session    optional     pam_gnome_keyring.so auto_start'
    install_text_file /etc/pam.d/greetd 0644 "$greetd_pam"

    run usermod --append --groups docker,libvirt "$TARGET_USER"

    if [[ "$(systemctl get-default 2>/dev/null || true)" != graphical.target ]]; then
        run systemctl set-default graphical.target
    fi

    log "Enabling services for the first boot"
    for service in "${SYSTEM_SERVICES[@]}"; do
        enable_service "$service"
    done
}

deploy_user_configuration() {
    local desktop_file

    log "Deploying user configuration"

    if [[ "$DRY_RUN" != true ]] \
        && ! as_target_user test -r "$REPO_ROOT/config/.config"; then
        die "$TARGET_USER cannot read $REPO_ROOT; clone the public repository beneath $TARGET_HOME."
    fi

    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME/.config"
    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME/.cache"
    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME/.local/share"
    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME/.local/state"
    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME/.cache/zsh"
    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME/.local/bin"
    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME/.local/share/applications"
    ensure_directory "$TARGET_USER" "$TARGET_GROUP" 0755 "$TARGET_HOME/.local/state/zsh"

    as_target_user stow \
        --dir "$REPO_ROOT" \
        --target "$TARGET_HOME" \
        --restow \
        --ignore='^\.config/(aerospace|borders|karabiner|sketchybar|skhd|spacebar|yabai)(/|$)' \
        --ignore='^\.config/hypr/.*\.bak$' \
        --ignore='^\.config/zsh/\.zcompdump' \
        config git

    if [[ -n "$DOTFILES_ROOT" ]]; then
        if [[ "$DRY_RUN" != true ]] \
            && ! as_target_user test -r "$DOTFILES_ROOT/git/.gitconfig.private"; then
            die "$TARGET_USER cannot read $DOTFILES_ROOT; clone the private repository beneath $TARGET_HOME."
        fi

        as_target_user stow \
            --dir "$DOTFILES_ROOT" \
            --target "$TARGET_HOME" \
            --restow \
            git

    else
        printf '  No dotfiles directory supplied; skipping private Git configuration.\n'
    fi

    configure_git_local

    for desktop_file in "$SCRIPT_DIR"/wm/desktop-files/*.desktop; do
        run install \
            -o "$TARGET_USER" \
            -g "$TARGET_GROUP" \
            -m 0644 \
            "$desktop_file" \
            "$TARGET_HOME/.local/share/applications/$(basename "$desktop_file")"
    done

    as_target_user xdg-mime default \
        org.gnome.Nautilus.desktop \
        inode/directory \
        application/x-gnome-saved-search

    as_target_user xdg-mime default \
        org.gnome.Loupe.desktop \
        image/apng \
        image/avif \
        image/bmp \
        image/gif \
        image/heic \
        image/jpeg \
        image/jxl \
        image/png \
        image/svg+xml \
        image/tiff \
        image/webp
}

install_user_tools() {
    local nvm_version="0.40.3"
    local candidate
    local candidate_binary

    log "Installing user-scoped development tools"

    if [[ ! -x "$TARGET_HOME/.local/bin/codex" ]]; then
        as_target_shell "set -o pipefail; curl -fsSL https://chatgpt.com/codex/install.sh | sh"
    else
        printf '  Codex is already installed.\n'
    fi

    if [[ ! -x "$TARGET_HOME/.local/bin/claude" ]]; then
        as_target_shell "set -o pipefail; curl -fsSL https://claude.ai/install.sh | bash"
    else
        printf '  Claude Code is already installed.\n'
    fi

    if [[ ! -x "$TARGET_HOME/.local/bin/fabric" ]]; then
        as_target_shell "set -o pipefail; curl -fsSL https://raw.githubusercontent.com/danielmiessler/fabric/main/scripts/installer/install.sh | bash"
    else
        printf '  Fabric is already installed.\n'
    fi

    if [[ "$DRY_RUN" != true ]]; then
        as_target_user "$TARGET_HOME/.local/bin/codex" --version >/dev/null
        as_target_user "$TARGET_HOME/.local/bin/claude" --version >/dev/null
        as_target_user "$TARGET_HOME/.local/bin/fabric" --version >/dev/null
    fi

    if [[ ! -s "$TARGET_HOME/.nvm/nvm.sh" ]]; then
        as_target_shell "curl -fsSL 'https://raw.githubusercontent.com/nvm-sh/nvm/v$nvm_version/install.sh' | env PROFILE=/dev/null NVM_DIR='$TARGET_HOME/.nvm' bash"
    else
        printf '  NVM is already installed.\n'
    fi

    as_target_shell "export NVM_DIR='$TARGET_HOME/.nvm'; source \"\$NVM_DIR/nvm.sh\"; nvm install --lts; nvm alias default 'lts/*'"

    if ! as_target_shell "export NVM_DIR='$TARGET_HOME/.nvm'; source \"\$NVM_DIR/nvm.sh\"; command -v copilot >/dev/null"; then
        as_target_shell "export NVM_DIR='$TARGET_HOME/.nvm'; source \"\$NVM_DIR/nvm.sh\"; npm install --global @github/copilot"
    fi

    if [[ ! -s "$TARGET_HOME/.sdkman/bin/sdkman-init.sh" ]]; then
        as_target_shell "curl -fsSL https://get.sdkman.io | bash"
    else
        printf '  SDKMAN is already installed.\n'
    fi

    for candidate in java maven gradle; do
        case "$candidate" in
            java) candidate_binary=java ;;
            maven) candidate_binary=mvn ;;
            gradle) candidate_binary=gradle ;;
        esac

        if [[ ! -x "$TARGET_HOME/.sdkman/candidates/$candidate/current/bin/$candidate_binary" ]]; then
            as_target_shell "export SDKMAN_DIR='$TARGET_HOME/.sdkman' SDKMAN_NON_INTERACTIVE=true; source \"\$SDKMAN_DIR/bin/sdkman-init.sh\"; sdk install '$candidate'"
        else
            printf '  SDKMAN candidate %s is already installed.\n' "$candidate"
        fi
    done

    for candidate in 'poetry' 'beancount==2.3.6' 'fava'; do
        if ! as_target_user pipx list --short | awk '{print $1}' | grep -Fxq "${candidate%%==*}"; then
            as_target_user pipx install "$candidate"
        else
            printf '  pipx package %s is already installed.\n' "${candidate%%==*}"
        fi
    done

    as_target_user xdg-user-dirs-update
}

install_herdr_plugins() {
    local plugin_id="vim-herdr-navigation"
    local plugin_source="paulbkim-dev/vim-herdr-navigation"
    local plugin_ref="79679dacc791f70fc34de8b29a3cf9706c0f5b2f"
    local plugins_json

    log "Installing Herdr plugins"

    if [[ "$DRY_RUN" == true ]]; then
        as_target_user herdr plugin install \
            "$plugin_source" \
            --ref "$plugin_ref" \
            --yes
        return 0
    fi

    plugins_json="$(as_target_user herdr plugin list --plugin "$plugin_id" --json)"
    if ! jq -e --arg id "$plugin_id" \
        '.result.plugins | any(.plugin_id == $id)' \
        <<<"$plugins_json" >/dev/null; then
        as_target_user herdr plugin install \
            "$plugin_source" \
            --ref "$plugin_ref" \
            --yes
        return 0
    fi

    if jq -e --arg id "$plugin_id" \
        '.result.plugins | any(.plugin_id == $id and .enabled)' \
        <<<"$plugins_json" >/dev/null; then
        printf '  Herdr plugin %s is already installed and enabled.\n' "$plugin_id"
        return 0
    fi

    as_target_user herdr plugin enable "$plugin_id"
}

main() {
    parse_arguments "$@"
    require_arch
    require_root
    infer_target_user
    validate_dotfiles_source

    log "Arch Hyprland workstation bootstrap"
    printf '  Repository: %s\n' "$REPO_ROOT"
    printf '  Target user: %s\n' "$TARGET_USER"
    [[ -n "$DOTFILES_ROOT" ]] && printf '  Dotfiles: %s\n' "$DOTFILES_ROOT"
    [[ "$DRY_RUN" == true ]] && printf '  Mode: dry run\n'

    enable_multilib
    install_bootstrap_packages
    configure_target_user
    configure_sudo
    install_paru
    install_workstation_packages
    configure_system
    configure_memory_management
    deploy_user_configuration

    log "Installing and verifying fonts"
    as_target_user "$SCRIPT_DIR/fonts.sh"

    install_user_tools
    install_herdr_plugins

    log "Bootstrap complete"
    printf 'Reboot into the installed system and select Hyprland in greetd.\n'
    printf 'Group membership changes take effect at the next login.\n'
    printf 'After the first graphical login, run: %s/post-install.sh\n' "$SCRIPT_DIR"
}

main "$@"
