#!/usr/bin/env bash

# Reader for the cross-platform package manifest. Callers may override YQ_BIN
# when validating with a temporary go-yq binary.

SHARED_PACKAGES_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SHARED_PACKAGES_FILE="${SHARED_PACKAGES_FILE:-$(cd -- "$SHARED_PACKAGES_LIB_DIR/.." && pwd)/packages.yaml}"
YQ_BIN="${YQ_BIN:-yq}"

require_shared_package_reader() {
    command -v "$YQ_BIN" >/dev/null 2>&1 || {
        printf 'error: go-yq is required to read %s\n' "$SHARED_PACKAGES_FILE" >&2
        return 1
    }

    [[ -r "$SHARED_PACKAGES_FILE" ]] || {
        printf 'error: shared package manifest is not readable: %s\n' "$SHARED_PACKAGES_FILE" >&2
        return 1
    }
}

shared_packages_query() {
    local query="$1"
    "$YQ_BIN" eval --no-colors --unwrapScalar "$query" "$SHARED_PACKAGES_FILE"
}

shared_arch_pacman_packages() {
    shared_packages_query '.packages[] | .arch.pacman[]?'
}

shared_arch_aur_packages() {
    shared_packages_query '.packages[] | .arch.aur[]?'
}

shared_macos_formulae() {
    shared_packages_query '.packages[] | .macos.brew.formula[]?'
}

shared_macos_casks() {
    shared_packages_query '.packages[] | .macos.brew.cask[]?'
}

validate_shared_package_manifest() {
    local invalid_entries
    local duplicate_arch_packages
    local duplicate_macos_packages

    require_shared_package_reader || return 1

    [[ "$(shared_packages_query '.schema')" == 1 ]] || {
        printf 'error: unsupported shared package manifest schema\n' >&2
        return 1
    }
    [[ "$(shared_packages_query '.packages | type')" == '!!map' ]] || {
        printf 'error: shared package manifest must contain a packages mapping\n' >&2
        return 1
    }

    invalid_entries="$(
        shared_packages_query '
            .packages | to_entries[] |
            select(
                (.value.type != "app" and .value.type != "cli") or
                (((.value.arch.pacman // []) + (.value.arch.aur // [])) | length == 0) or
                (((.value.macos.brew.formula // []) + (.value.macos.brew.cask // [])) | length == 0)
            ) |
            .key
        '
    )"
    [[ -z "$invalid_entries" ]] || {
        printf 'error: shared packages require a type and non-empty Arch and macOS mappings: %s\n' \
            "$invalid_entries" >&2
        return 1
    }

    duplicate_arch_packages="$(
        {
            shared_arch_pacman_packages
            shared_arch_aur_packages
        } | sort | uniq -d
    )"
    [[ -z "$duplicate_arch_packages" ]] || {
        printf 'error: duplicate Arch mappings in shared package manifest: %s\n' \
            "$duplicate_arch_packages" >&2
        return 1
    }

    duplicate_macos_packages="$(
        {
            shared_macos_formulae
            shared_macos_casks
        } | sort | uniq -d
    )"
    [[ -z "$duplicate_macos_packages" ]] || {
        printf 'error: duplicate macOS mappings in shared package manifest: %s\n' \
            "$duplicate_macos_packages" >&2
        return 1
    }
}
