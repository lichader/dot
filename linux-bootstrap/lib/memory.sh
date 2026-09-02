#!/usr/bin/env bash

# Memory-management implementation for linux-bootstrap/bootstrap.sh. This file
# is sourced after common.sh and is not a public entrypoint.

FSTAB_PATH="${FSTAB_PATH:-/etc/fstab}"
LEGACY_ZRAM_SYSCTL_PATH="${LEGACY_ZRAM_SYSCTL_PATH:-/etc/sysctl.d/99-zram.conf}"
MEMORY_SYSCTL_PATH="${MEMORY_SYSCTL_PATH:-/etc/sysctl.d/99-memory.conf}"
ZRAM_GENERATOR_CONFIG_PATH="${ZRAM_GENERATOR_CONFIG_PATH:-/etc/systemd/zram-generator.conf}"

install_rewritten_file() {
    local source="$1"
    local destination="$2"

    [[ ! -L "$destination" ]] \
        || die "Refusing to replace symbolic link: $destination"

    if [[ -f "$destination" ]] && cmp -s -- "$source" "$destination"; then
        printf '  %s is already configured.\n' "$destination"
        rm -f -- "$source"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        printf '  + update %s while preserving unrelated settings\n' "$destination"
    else
        install -Dm0644 "$source" "$destination"
    fi

    rm -f -- "$source"
}

configure_zram_generator() {
    local in_zram0=false
    local line=""
    local section_pattern='^[[:space:]]*\[[^]]+\]'
    local setting_pattern='^[[:space:]]*(zram-size|zram-fraction|max-zram-size|compression-algorithm|swap-priority)[[:space:]]*='
    local temporary
    local zram0_found=false
    local zram0_pattern='^[[:space:]]*\[zram0\][[:space:]]*([#;].*)?$'

    temporary="$(mktemp)"

    if [[ -f "$ZRAM_GENERATOR_CONFIG_PATH" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ $section_pattern ]]; then
                in_zram0=false
                if [[ "$line" =~ $zram0_pattern ]]; then
                    in_zram0=true
                    if [[ "$zram0_found" == false ]]; then
                        printf '%s\n' "$line" >>"$temporary"
                        printf '%s\n' \
                            'zram-size = ram / 2' \
                            'compression-algorithm = zstd' \
                            'swap-priority = 100' \
                            >>"$temporary"
                        zram0_found=true
                        continue
                    fi
                fi
            fi

            if [[ "$in_zram0" == true && "$line" =~ $setting_pattern ]]; then
                continue
            fi

            printf '%s\n' "$line" >>"$temporary"
        done <"$ZRAM_GENERATOR_CONFIG_PATH"
    fi

    if [[ "$zram0_found" == false ]]; then
        [[ ! -s "$temporary" ]] || printf '\n' >>"$temporary"
        printf '%s\n' \
            '[zram0]' \
            'zram-size = ram / 2' \
            'compression-algorithm = zstd' \
            'swap-priority = 100' \
            >>"$temporary"
    fi

    install_rewritten_file "$temporary" "$ZRAM_GENERATOR_CONFIG_PATH"
}

configure_swappiness_file() {
    local line=""
    local setting_pattern='^[[:space:]]*vm\.swappiness[[:space:]]*='
    local setting_written=false
    local temporary

    temporary="$(mktemp)"

    if [[ -f "$MEMORY_SYSCTL_PATH" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ $setting_pattern ]]; then
                if [[ "$setting_written" == false ]]; then
                    printf '%s\n' 'vm.swappiness=100' >>"$temporary"
                    setting_written=true
                fi
                continue
            fi
            printf '%s\n' "$line" >>"$temporary"
        done <"$MEMORY_SYSCTL_PATH"
    fi

    if [[ "$setting_written" == false ]]; then
        printf '%s\n' 'vm.swappiness=100' >>"$temporary"
    fi

    install_rewritten_file "$temporary" "$MEMORY_SYSCTL_PATH"
}

remove_legacy_swappiness_setting() {
    local line=""
    local setting_found=false
    local setting_pattern='^[[:space:]]*vm\.swappiness[[:space:]]*='
    local temporary

    [[ -f "$LEGACY_ZRAM_SYSCTL_PATH" ]] || return 0

    temporary="$(mktemp)"
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ $setting_pattern ]]; then
            setting_found=true
            continue
        fi
        printf '%s\n' "$line" >>"$temporary"
    done <"$LEGACY_ZRAM_SYSCTL_PATH"

    if [[ "$setting_found" == true ]]; then
        install_rewritten_file "$temporary" "$LEGACY_ZRAM_SYSCTL_PATH"
    else
        rm -f -- "$temporary"
    fi
}

swap_options_with_priority() {
    local options="$1"
    local option
    local priority_written=false
    local updated_options=""
    local option_parts=()

    IFS=',' read -r -a option_parts <<<"$options"
    for option in "${option_parts[@]}"; do
        if [[ "$option" == pri=* ]]; then
            [[ "$priority_written" == true ]] && continue
            option='pri=10'
            priority_written=true
        fi

        if [[ -n "$updated_options" ]]; then
            updated_options+=",$option"
        else
            updated_options="$option"
        fi
    done

    if [[ "$priority_written" == false ]]; then
        updated_options+=",pri=10"
        updated_options="${updated_options#,}"
    fi

    printf '%s\n' "$updated_options"
}

configure_disk_swap_priority() {
    local active_disk_swap=""
    local disk_swap_found=false
    local line=""
    local line_pattern='^([[:space:]]*[^#[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+swap[[:space:]]+)([^[:space:]]+)(.*)$'
    local options
    local output_line
    local temporary
    local updated_options

    [[ -f "$FSTAB_PATH" ]] || die "Missing filesystem table: $FSTAB_PATH"
    temporary="$(mktemp)"

    while IFS= read -r line || [[ -n "$line" ]]; do
        output_line="$line"
        if [[ "$line" =~ $line_pattern ]]; then
            disk_swap_found=true
            options="${BASH_REMATCH[2]}"
            updated_options="$(swap_options_with_priority "$options")"
            output_line="${BASH_REMATCH[1]}${updated_options}${BASH_REMATCH[3]}"
        fi
        printf '%s\n' "$output_line" >>"$temporary"
    done <"$FSTAB_PATH"

    if [[ "$disk_swap_found" == false ]]; then
        rm -f -- "$temporary"
        active_disk_swap="$(
            swapon --noheadings --raw --show=NAME 2>/dev/null \
                | awk '$1 !~ /^\/dev\/zram[0-9]+$/ { print $1 }' \
                | paste -sd, - \
                || true
        )"
        if [[ -n "$active_disk_swap" ]]; then
            warn "Non-zram swap is active but not configured in $FSTAB_PATH: $active_disk_swap"
        else
            warn "No disk-backed swap is configured; create it separately during Archinstall or manually."
        fi
        return 0
    fi

    install_rewritten_file "$temporary" "$FSTAB_PATH"
}

configure_memory_management() {
    local command_name
    local current_swappiness

    log "Configuring memory management"

    for command_name in sysctl swapon zramctl; do
        require_command "$command_name"
    done

    configure_zram_generator
    configure_swappiness_file
    remove_legacy_swappiness_setting
    configure_disk_swap_priority

    run sysctl -w vm.swappiness=100

    log "Verifying active memory management"
    if [[ "$DRY_RUN" == true ]]; then
        run sysctl vm.swappiness
        run zramctl
        run swapon --show
        return 0
    fi

    current_swappiness="$(sysctl -n vm.swappiness)"
    [[ "$current_swappiness" == 100 ]] \
        || die "Failed to apply vm.swappiness=100; current value is $current_swappiness"

    sysctl vm.swappiness
    zramctl
    swapon --show
}
