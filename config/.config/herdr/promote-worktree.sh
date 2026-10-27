#!/usr/bin/env bash
set -Eeuo pipefail

show_error() {
    local status="$?"
    trap - ERR
    printf '\nPromotion failed. Review the error above.\nPress Enter to close.' >&2
    read -r || true
    exit "$status"
}

trap show_error ERR

HERDR_BIN="${HERDR_BIN_PATH:-herdr}"
WORKSPACE_ID="${HERDR_ACTIVE_WORKSPACE_ID:-}"

if [[ -z "$WORKSPACE_ID" ]]; then
    printf 'Run this command from the Herdr promotion popup.\n' >&2
    false
fi

command -v "$HERDR_BIN" >/dev/null
command -v git >/dev/null
command -v jq >/dev/null

# Resolve the captured workspace, rather than whichever workspace is now focused.
# Its checkout is authoritative even when the popup was opened from a subdirectory.
WORKSPACES_JSON="$("$HERDR_BIN" workspace list)"
WORKTREE_PATH="$(jq -er --arg id "$WORKSPACE_ID" '
    .result.workspaces[]
    | select(.workspace_id == $id)
    | .worktree.checkout_path
    | select(type == "string" and length > 0)
' <<<"$WORKSPACES_JSON")"

cd -- "$WORKTREE_PATH"
CURRENT_BRANCH="$(git symbolic-ref --quiet --short HEAD)"
printf 'Current branch: %s\nNew branch (blank to cancel): ' "$CURRENT_BRANCH"
if ! IFS= read -r NEW_BRANCH || [[ -z "$NEW_BRANCH" ]]; then
    exit 0
fi

if ! git check-ref-format "refs/heads/$NEW_BRANCH"; then
    printf 'Invalid branch name: %s\n' "$NEW_BRANCH" >&2
    false
fi
git switch -c "$NEW_BRANCH"

# Match the label convention used by the Worktrunk post-switch hook.
WORKSPACE_LABEL="${NEW_BRANCH##*/}"
printf 'Branch created. Updating workspace name to %s...\n' "$WORKSPACE_LABEL"
"$HERDR_BIN" workspace rename "$WORKSPACE_ID" "$WORKSPACE_LABEL" >/dev/null
