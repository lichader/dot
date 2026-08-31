#!/usr/bin/env bash

set -euo pipefail

readonly EXPECTED_DISK_SWAP_BYTES=$((32 * 1024 * 1024 * 1024))
readonly DISK_SWAP_TOLERANCE_BYTES=$((2 * 1024 * 1024 * 1024))
readonly EFI_SYSTEM_PARTITION_GUID="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"

PASS_COUNT=0
WARNING_COUNT=0
FAILURE_COUNT=0

usage() {
    cat <<'EOF'
Usage: ./linux-bootstrap/post-check.sh

Verify the expected Arch partition, Btrfs subvolume, compression, and swap
layout after booting the installed system. This script is read-only.
EOF
}

pass() {
    printf '  [PASS] %s\n' "$*"
    ((PASS_COUNT += 1))
}

warn() {
    printf '  [WARN] %s\n' "$*" >&2
    ((WARNING_COUNT += 1))
}

fail() {
    printf '  [FAIL] %s\n' "$*" >&2
    ((FAILURE_COUNT += 1))
}

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'error: required command is unavailable: %s\n' "$command_name" >&2
        exit 2
    fi
}

mount_info() {
    local mountpoint="$1"

    findmnt \
        --noheadings \
        --raw \
        --output SOURCE,FSTYPE,FSROOT,UUID,OPTIONS \
        --mountpoint "$mountpoint" \
        2>/dev/null
}

check_boot_mount() {
    local info=""
    local source=""
    local fstype=""
    local partition_type=""

    info="$(
        findmnt \
            --noheadings \
            --raw \
            --output SOURCE,FSTYPE \
            --mountpoint /boot \
            2>/dev/null \
            || true
    )"
    if [[ -z "$info" ]]; then
        fail "/boot is not a distinct mounted filesystem"
        return
    fi

    read -r source fstype <<<"$info"
    if [[ "$fstype" == "vfat" ]]; then
        pass "/boot uses a FAT filesystem ($source)"
    else
        fail "/boot uses $fstype instead of vfat ($source)"
    fi

    partition_type="$(
        lsblk --nodeps --noheadings --raw --output PARTTYPE "$source" 2>/dev/null \
            || true
    )"
    if [[ "${partition_type,,}" == "$EFI_SYSTEM_PARTITION_GUID" ]]; then
        pass "$source is marked as an EFI system partition"
    else
        fail "$source does not have the EFI system partition type GUID"
    fi
}

check_btrfs_mount() {
    local mountpoint="$1"
    local expected_fsroot="$2"
    local root_uuid="$3"
    local info=""
    local source=""
    local fstype=""
    local fsroot=""
    local uuid=""
    local options=""

    info="$(mount_info "$mountpoint" || true)"
    if [[ -z "$info" ]]; then
        fail "$mountpoint is not a distinct mountpoint for $expected_fsroot"
        return
    fi

    read -r source fstype fsroot uuid options <<<"$info"

    if [[ "$fstype" == "btrfs" ]]; then
        pass "$mountpoint uses Btrfs ($source)"
    else
        fail "$mountpoint uses $fstype instead of Btrfs ($source)"
    fi

    if [[ "$fsroot" == "$expected_fsroot" ]]; then
        pass "$mountpoint maps to subvolume $expected_fsroot"
    else
        fail "$mountpoint maps to $fsroot instead of $expected_fsroot"
    fi

    if [[ "$options" =~ (^|,)(compress|compress-force)=zstd(:[0-9]+)?(,|$) ]]; then
        pass "$mountpoint has Zstd compression enabled"
    else
        fail "$mountpoint does not have compress=zstd in its mount options"
    fi

    if [[ -n "$root_uuid" && "$uuid" == "$root_uuid" ]]; then
        pass "$mountpoint belongs to the root Btrfs filesystem ($uuid)"
    elif [[ "$mountpoint" != "/" ]]; then
        fail "$mountpoint is on UUID $uuid instead of root UUID $root_uuid"
    fi
}

check_disk_swap() {
    local swap_rows=""
    local name=""
    local type=""
    local size=""
    local priority=""
    local lower_bound=$((EXPECTED_DISK_SWAP_BYTES - DISK_SWAP_TOLERANCE_BYTES))
    local upper_bound=$((EXPECTED_DISK_SWAP_BYTES + DISK_SWAP_TOLERANCE_BYTES))
    local disk_swap_found=false

    swap_rows="$(swapon --bytes --noheadings --raw --show=NAME,TYPE,SIZE,PRIO)"
    while read -r name type size priority; do
        [[ -n "$name" ]] || continue
        [[ "$name" != /dev/zram* ]] || continue

        if [[ "$type" == "partition" ]]; then
            disk_swap_found=true
            pass "disk-backed swap partition is active ($name)"

            if ((size >= lower_bound && size <= upper_bound)); then
                pass "disk swap is approximately 32 GiB ($((size / 1024 / 1024 / 1024)) GiB)"
            else
                warn "disk swap is $((size / 1024 / 1024 / 1024)) GiB; the recommended size is 32 GiB"
            fi

            if ((priority < 100)); then
                pass "disk swap priority $priority is lower than Zram priority 100"
            else
                warn "disk swap priority $priority should be lower than Zram priority 100"
            fi
        fi
    done <<<"$swap_rows"

    if [[ "$disk_swap_found" == false ]]; then
        fail "no active disk-backed swap partition was found"
    fi
}

check_zram() {
    local name=""
    local priority=""
    local zram_found=false
    local algorithms=""

    while read -r name priority; do
        if [[ "$name" == "/dev/zram0" ]]; then
            zram_found=true
            if [[ "$priority" == "100" ]]; then
                pass "/dev/zram0 is active with priority 100"
            else
                warn "/dev/zram0 is active with priority $priority instead of 100"
            fi
            break
        fi
    done < <(swapon --noheadings --raw --show=NAME,PRIO)

    if [[ "$zram_found" == false ]]; then
        fail "/dev/zram0 is not active as swap"
        return
    fi

    if [[ -r /sys/block/zram0/comp_algorithm ]]; then
        algorithms="$(< /sys/block/zram0/comp_algorithm)"
        if [[ "$algorithms" == *"[zstd]"* ]]; then
            pass "/dev/zram0 uses Zstd compression"
        else
            fail "/dev/zram0 does not use Zstd compression ($algorithms)"
        fi
    else
        fail "cannot read /dev/zram0 compression algorithm"
    fi
}

case "${1:-}" in
    "") ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

for COMMAND_NAME in findmnt lsblk swapon zramctl; do
    require_command "$COMMAND_NAME"
done

printf 'Block devices\n'
lsblk --output NAME,PATH,TYPE,SIZE,FSTYPE,FSVER,PARTTYPENAME,MOUNTPOINTS

printf '\nMounted filesystems\n'
findmnt \
    --real \
    --output TARGET,SOURCE,FSTYPE,FSROOT,OPTIONS

printf '\nActive swap\n'
swapon --show=NAME,TYPE,SIZE,USED,PRIO
zramctl

printf '\nStorage checks\n'
ROOT_UUID="$(findmnt --noheadings --raw --output UUID --mountpoint / 2>/dev/null || true)"
readonly ROOT_UUID
check_boot_mount
check_btrfs_mount / /@ "$ROOT_UUID"
check_btrfs_mount /home /@home "$ROOT_UUID"
check_btrfs_mount /var/log /@log "$ROOT_UUID"
check_btrfs_mount /var/cache/pacman/pkg /@pkg "$ROOT_UUID"
check_disk_swap
check_zram

printf '\nSummary: %d passed, %d warning(s), %d failed.\n' \
    "$PASS_COUNT" "$WARNING_COUNT" "$FAILURE_COUNT"

if ((FAILURE_COUNT > 0)); then
    exit 1
fi
