#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/shared-packages.sh
source "$REPO_ROOT/lib/shared-packages.sh"

FORMULAE=()
CASKS=()

if [[ "$(uname -s)" != Darwin ]]; then
    printf 'error: this package installer supports macOS only\n' >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    printf 'error: install Homebrew before running this script: https://brew.sh\n' >&2
    exit 1
fi

# The manifest cannot install its own parser, so yq is an explicit bootstrap
# dependency on both platforms.
if ! command -v yq >/dev/null 2>&1; then
    brew install yq
fi

validate_shared_package_manifest

while IFS= read -r package; do
    [[ -n "$package" ]] && FORMULAE[${#FORMULAE[@]}]="$package"
done < <(shared_macos_formulae)

while IFS= read -r package; do
    [[ -n "$package" ]] && CASKS[${#CASKS[@]}]="$package"
done < <(shared_macos_casks)

if ((${#FORMULAE[@]} > 0)); then
    brew install "${FORMULAE[@]}"
fi

if ((${#CASKS[@]} > 0)); then
    brew install --cask "${CASKS[@]}"
fi
