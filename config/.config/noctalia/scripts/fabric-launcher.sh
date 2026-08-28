#!/usr/bin/env bash

set -u

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

run_fabric() {
    local pattern="$1"
    local url="$2"

    while ! is_youtube_url "$url"; do
        read -r -p "YouTube URL: " url || exit 0
        if ! is_youtube_url "$url"; then
            printf 'Enter a valid YouTube URL.\n' >&2
        fi
    done

    exec fabric \
        --pattern "$pattern" \
        --stream \
        --youtube "$url"
}

if [[ "${1:-}" == "--run" ]]; then
    shift
    run_fabric "$@"
fi

require_command fabric
require_command ghostty
require_command noctalia

selection="$(printf '%s\n' \
    "Summarize" \
    "Extract wisdom" \
    | noctalia dmenu --prompt "Fabric pattern")" || exit 0

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

exec ghostty \
    --title="Fabric: $selection" \
    --wait-after-command=true \
    -e "${BASH_SOURCE[0]}" \
        --run \
        "$pattern" \
        "$url"
