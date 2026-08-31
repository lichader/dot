#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_FIXTURE=""
DRY_RUN_OUTPUT=""
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
    /etc/zsh/zshenv \
    /.cache \
    /.local/share \
    /.local/state \
    /.cache/zsh \
    /.local/state/zsh; do
    grep -Fq "$expected_path" <<<"$DRY_RUN_OUTPUT" \
        || fail "bootstrap omits essential Zsh setup path: $expected_path"
done

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
