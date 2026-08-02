#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_FIXTURE=""

cleanup() {
    if [[ -n "$DOTFILES_FIXTURE" && -d "$DOTFILES_FIXTURE" ]]; then
        rm -rf -- "$DOTFILES_FIXTURE"
    fi
}

trap cleanup EXIT

# shellcheck source=setup/lib/packages.sh
source "$SCRIPT_DIR/lib/packages.sh"

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

printf 'Checking shell syntax...\n'
for script in "$SCRIPT_DIR/bootstrap.sh" "$SCRIPT_DIR/fonts.sh" "$SCRIPT_DIR/lib/"*.sh; do
    bash -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
    printf 'Running ShellCheck...\n'
    shellcheck \
        "$SCRIPT_DIR/bootstrap.sh" \
        "$SCRIPT_DIR/fonts.sh" \
        "$SCRIPT_DIR/lib/"*.sh
fi

printf 'Checking package manifest invariants...\n'
duplicates="$(
    printf '%s\n' "${BOOTSTRAP_PACKAGES[@]}" "${OFFICIAL_PACKAGES[@]}" "${AUR_PACKAGES[@]}" \
        | sort \
        | uniq -d
)"
[[ -z "$duplicates" ]] || fail "duplicate package declarations: $duplicates"

forbidden="$(
    printf '%s\n' "${OFFICIAL_PACKAGES[@]}" "${AUR_PACKAGES[@]}" \
        | grep -E '^(sway|swaybg|swayidle|swaylock|plasma.*|kwin.*|dolphin|konsole|kate|ark|okular)$' \
        || true
)"
[[ -z "$forbidden" ]] || fail "Sway/KDE packages are intentionally excluded: $forbidden"

printf 'Checking official package availability...\n'
if ! pacman -Si "${BOOTSTRAP_PACKAGES[@]}" "${OFFICIAL_PACKAGES[@]}" >/dev/null 2>&1; then
    for package in "${BOOTSTRAP_PACKAGES[@]}" "${OFFICIAL_PACKAGES[@]}"; do
        pacman -Si "$package" >/dev/null 2>&1 \
            || fail "official package is unavailable: $package"
    done
fi

if command -v paru >/dev/null 2>&1; then
    printf 'Checking AUR package availability...\n'
    if ! paru -Si "${AUR_PACKAGES[@]}" >/dev/null 2>&1; then
        for package in "${AUR_PACKAGES[@]}"; do
            paru -Si "$package" >/dev/null 2>&1 \
                || fail "AUR package is unavailable: $package"
        done
    fi
else
    printf 'Skipping AUR availability checks because paru is not installed.\n'
fi

printf 'Checking the public bootstrap interface...\n'
"$SCRIPT_DIR/bootstrap.sh" --user "${SUDO_USER:-${USER:-lichader}}" --dry-run >/dev/null

DOTFILES_FIXTURE="$(mktemp -d)"
mkdir -p \
    "$DOTFILES_FIXTURE/config" \
    "$DOTFILES_FIXTURE/git" \
    "$DOTFILES_FIXTURE/ideavim"
"$SCRIPT_DIR/bootstrap.sh" \
    --user "${SUDO_USER:-${USER:-lichader}}" \
    --dotfiles-dir "$DOTFILES_FIXTURE" \
    --dry-run \
    >/dev/null

printf 'Setup checks passed.\n'
