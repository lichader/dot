#!/usr/bin/env bash

set -Eeuo pipefail

PRIVATE_REPOSITORY="lichader/post-setup-config"
PRIVATE_CONFIG_DIR="$HOME/post-setup-config"
LOCAL_GIT_CONFIG="$HOME/.gitconfig.local"
DRY_RUN=false
SKIP_TAILSCALE=false

usage() {
    cat <<'EOF'
Usage: linux-bootstrap/post-install.sh [options]

Finish the interactive, user-scoped workstation setup after the first login.

Options:
  --config-dir PATH   Private configuration checkout (default: ~/post-setup-config)
  --repo OWNER/REPO   Private repository (default: lichader/post-setup-config)
  --skip-tailscale    Do not connect Tailscale
  --dry-run           Print planned mutations without performing them
  -h, --help          Show this help

Run this script as the normal desktop user, not as root.
EOF
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

print_command() {
    printf '  +'
    printf ' %q' "$@"
    printf '\n'
}

run() {
    if [[ "$DRY_RUN" == true ]]; then
        print_command "$@"
        return 0
    fi

    "$@"
}

parse_arguments() {
    while (($# > 0)); do
        case "$1" in
            --config-dir)
                (($# >= 2)) || die "--config-dir requires a path."
                PRIVATE_CONFIG_DIR="$2"
                shift 2
                ;;
            --repo)
                (($# >= 2)) || die "--repo requires OWNER/REPO."
                PRIVATE_REPOSITORY="$2"
                shift 2
                ;;
            --skip-tailscale)
                SKIP_TAILSCALE=true
                shift
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

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command is unavailable: $1"
}

validate_environment() {
    [[ "$DRY_RUN" == true || "$EUID" -ne 0 ]] \
        || die "Run this script as the normal desktop user, not as root."
    [[ "$PRIVATE_REPOSITORY" =~ ^[^/[:space:]]+/[^/[:space:]]+$ ]] \
        || die "--repo must use the OWNER/REPO form."

    if [[ "$DRY_RUN" != true ]]; then
        [[ -L "$HOME/.gitconfig" || -f "$HOME/.gitconfig" ]] \
            || die "Public Git configuration is missing; run bootstrap.sh first."
        require_command gh
        require_command git
        require_command stow
    fi

    PRIVATE_CONFIG_DIR="$(realpath -m -- "$PRIVATE_CONFIG_DIR")"
    [[ "$PRIVATE_CONFIG_DIR" != "$HOME" && "$PRIVATE_CONFIG_DIR/" == "$HOME/"* ]] \
        || die \
            "Keep the private checkout beneath your home directory: $PRIVATE_CONFIG_DIR"
}

configure_github() {
    printf '\nGitHub authentication\n'

    if [[ "$DRY_RUN" == true ]]; then
        print_command env GIT_CONFIG_GLOBAL="$LOCAL_GIT_CONFIG" \
            gh auth login --hostname github.com --web --git-protocol https
    elif gh auth status --hostname github.com >/dev/null 2>&1; then
        printf '  GitHub CLI is already authenticated.\n'
    else
        env GIT_CONFIG_GLOBAL="$LOCAL_GIT_CONFIG" \
            gh auth login --hostname github.com --web --git-protocol https
    fi

    # Keep the GitHub-specific credential helper in the untracked machine-local
    # overlay instead of allowing gh to modify the public ~/.gitconfig symlink.
    run env GIT_CONFIG_GLOBAL="$LOCAL_GIT_CONFIG" \
        gh auth setup-git --hostname github.com
}

validate_existing_checkout() {
    local origin

    [[ -d "$PRIVATE_CONFIG_DIR/.git" ]] \
        || die "Existing path is not a Git checkout: $PRIVATE_CONFIG_DIR"

    origin="$(git -C "$PRIVATE_CONFIG_DIR" remote get-url origin 2>/dev/null || true)"
    case "$origin" in
        "git@github.com:$PRIVATE_REPOSITORY.git" \
        | "https://github.com/$PRIVATE_REPOSITORY" \
        | "https://github.com/$PRIVATE_REPOSITORY.git" \
        | "ssh://git@github.com/$PRIVATE_REPOSITORY.git") ;;
        *) die "Existing checkout has an unexpected origin: ${origin:-<none>}" ;;
    esac
}

deploy_private_config() {
    local private_git_file=""

    printf '\nPrivate post-setup configuration\n'

    if [[ -e "$PRIVATE_CONFIG_DIR" ]]; then
        validate_existing_checkout
        printf '  Private repository is already cloned.\n'
    else
        run gh repo clone "$PRIVATE_REPOSITORY" "$PRIVATE_CONFIG_DIR"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_command stow \
            --dir "$PRIVATE_CONFIG_DIR" \
            --target "$HOME" \
            --restow \
            git
        return 0
    fi

    for private_git_file in \
        .gitconfig.private \
        .gitconfig_personal \
        .gitconfig_work; do
        [[ -f "$PRIVATE_CONFIG_DIR/git/$private_git_file" ]] \
            || die "Private checkout is missing git/$private_git_file."
    done

    stow \
        --dir "$PRIVATE_CONFIG_DIR" \
        --target "$HOME" \
        --restow \
        git

    for private_git_file in \
        .gitconfig.private \
        .gitconfig_personal \
        .gitconfig_work; do
        [[ -L "$HOME/$private_git_file" || -f "$HOME/$private_git_file" ]] \
            || die "Private Git configuration was not deployed: $private_git_file"
    done
}

connect_tailscale() {
    [[ "$SKIP_TAILSCALE" == false ]] || return 0

    printf '\nTailscale\n'
    if [[ "$DRY_RUN" == true ]]; then
        print_command sudo tailscale up
        return 0
    fi

    command -v tailscale >/dev/null 2>&1 || return 0
    if tailscale status >/dev/null 2>&1; then
        printf '  Tailscale is already connected.\n'
        return 0
    fi

    sudo tailscale up
}

main() {
    parse_arguments "$@"
    validate_environment

    printf 'Post-install workstation setup\n'
    printf '  Private repository: %s\n' "$PRIVATE_REPOSITORY"
    printf '  Checkout: %s\n' "$PRIVATE_CONFIG_DIR"
    [[ "$DRY_RUN" == true ]] && printf '  Mode: dry run\n'

    connect_tailscale
    configure_github
    deploy_private_config

    printf '\nPost-install setup complete.\n'
}

main "$@"
