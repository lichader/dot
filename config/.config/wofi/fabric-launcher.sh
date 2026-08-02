#!/usr/bin/env bash

set -u

readonly WOFI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/wofi/config"
readonly WOFI_STYLE="${XDG_CONFIG_HOME:-$HOME/.config}/wofi/style.css"

notify_error() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send --urgency=critical "Fabric launcher" "$1"
    fi
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        notify_error "Required command not found: $1"
        exit 1
    fi
}

is_youtube_url() {
    [[ "$1" =~ ^https?://([^/]+\.)?(youtube\.com|youtube-nocookie\.com|youtu\.be)(/|$) ]]
}

prompt_for_url() {
    local url

    while true; do
        url="$(wofi \
            --dmenu \
            --exec-search \
            --prompt "YouTube URL" \
            --conf "$WOFI_CONFIG" \
            --style "$WOFI_STYLE" \
            </dev/null)" || return 1

        if is_youtube_url "$url"; then
            printf '%s\n' "$url"
            return 0
        fi

        notify_error "Enter a valid YouTube URL"
    done
}

require_command fabric
require_command ghostty
require_command wofi

selection="$(printf '%s\n' \
    "Summarize" \
    "Extract wisdom" \
    | wofi \
        --dmenu \
        --insensitive \
        --prompt "Fabric pattern" \
        --conf "$WOFI_CONFIG" \
        --style "$WOFI_STYLE")" || exit 0

case "$selection" in
    "Summarize")
        pattern="summarize"
        ;;
    "Extract wisdom")
        pattern="extract_wisdom"
        ;;
    *)
        exit 0
        ;;
esac

url=""
if command -v wl-paste >/dev/null 2>&1; then
    clipboard="$(wl-paste --no-newline 2>/dev/null || true)"
    if is_youtube_url "$clipboard"; then
        url="$clipboard"
    fi
fi

if [[ -z "$url" ]]; then
    url="$(prompt_for_url)" || exit 0
fi

fabric_bin="$(command -v fabric)"

exec ghostty \
    --title="Fabric: $selection" \
    --wait-after-command=true \
    -e "$fabric_bin" \
        --pattern "$pattern" \
        --stream \
        --youtube "$url"
