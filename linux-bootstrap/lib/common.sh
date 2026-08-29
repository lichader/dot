#!/usr/bin/env bash

# Shared implementation for the Arch workstation bootstrap. This file is
# sourced by linux-bootstrap/bootstrap.sh and is not a public entrypoint.

log() {
    printf '\n\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

print_command() {
    printf '  +'
    printf ' %q' "$@"
    printf '\n'
}

run() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        print_command "$@"
        return 0
    fi

    "$@"
}

require_arch() {
    [[ -r /etc/arch-release ]] || die "This bootstrap supports Arch Linux only."
}

require_root() {
    if [[ "${DRY_RUN:-false}" != true && $EUID -ne 0 ]]; then
        die "Run this bootstrap as root (normally from arch-chroot)."
    fi
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

as_target_user() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        print_command runuser -u "$TARGET_USER" -- env \
            "HOME=$TARGET_HOME" \
            "USER=$TARGET_USER" \
            "LOGNAME=$TARGET_USER" \
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/bin" \
            "$@"
        return 0
    fi

    runuser -u "$TARGET_USER" -- env \
        "HOME=$TARGET_HOME" \
        "USER=$TARGET_USER" \
        "LOGNAME=$TARGET_USER" \
        "PATH=/usr/local/sbin:/usr/local/bin:/usr/bin" \
        "$@"
}

as_target_shell() {
    as_target_user /usr/bin/bash -c "$1"
}

pacman_install() {
    (($# > 0)) || return 0
    run pacman -S --needed --noconfirm "$@"
}

paru_install() {
    (($# > 0)) || return 0
    as_target_user paru -S \
        --needed \
        --noconfirm \
        --skipreview \
        --removemake \
        --cleanafter \
        --noinstalldebug \
        --pgpfetch \
        "$@"
}

enable_service() {
    local unit="$1"

    if systemctl is-enabled "$unit" >/dev/null 2>&1; then
        printf '  %s is already enabled.\n' "$unit"
        return 0
    fi

    # `enable` is deliberately used without `--now`: systemd is not running
    # as PID 1 while this script executes inside arch-chroot.
    run systemctl enable "$unit"
}

install_text_file() {
    local destination="$1"
    local mode="$2"
    local content="$3"
    local temporary

    if [[ -f "$destination" ]] && [[ "$(<"$destination")" == "$content" ]]; then
        printf '  %s is already configured.\n' "$destination"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == true ]]; then
        printf '  + install generated file %s (mode %s)\n' "$destination" "$mode"
        return 0
    fi

    temporary="$(mktemp)"
    printf '%s\n' "$content" >"$temporary"
    install -Dm"$mode" "$temporary" "$destination"
    rm -f "$temporary"
}

ensure_directory() {
    local owner="$1"
    local group="$2"
    local mode="$3"
    local directory="$4"

    run install -d -o "$owner" -g "$group" -m "$mode" "$directory"
}

configure_git_local() {
    local gitconfig="$TARGET_HOME/.gitconfig.local"
    local credential_helper="/usr/lib/git-core/git-credential-libsecret"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        print_command git config --file "$gitconfig" \
            --replace-all credential.helper "$credential_helper"
        return 0
    fi

    as_target_user touch "$gitconfig"
    as_target_user git config --file "$gitconfig" \
        --replace-all credential.helper "$credential_helper"
}
