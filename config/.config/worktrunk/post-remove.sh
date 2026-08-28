#!/usr/bin/env bash
set -euo pipefail

WORKTREE_PATH="${1:?usage: post-remove.sh WORKTREE_PATH}"

if [[ "${HERDR_ENV:-}" != "1" ]]; then
    printf 'Not running inside Herdr; skipping workspace cleanup for %s\n' "$WORKTREE_PATH" >&2
    exit 0
fi

if ! command -v herdr >/dev/null 2>&1; then
    printf 'herdr is required to clean up the workspace\n' >&2
    exit 127
fi

if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required to clean up the Herdr workspace\n' >&2
    exit 127
fi

WORKSPACES_JSON="$(herdr workspace list)"
MATCH_COUNT="$(jq --arg path "$WORKTREE_PATH" '
    [
        .result.workspaces[]
        | select(.worktree != null and .worktree.checkout_path == $path)
    ]
    | length
' <<<"$WORKSPACES_JSON")"

case "$MATCH_COUNT" in
    0)
        exit 0
        ;;
    1)
        WORKSPACE_ID="$(jq -er --arg path "$WORKTREE_PATH" '
            .result.workspaces[]
            | select(.worktree != null and .worktree.checkout_path == $path)
            | .workspace_id
        ' <<<"$WORKSPACES_JSON")"
        herdr workspace close "$WORKSPACE_ID" >/dev/null
        ;;
    *)
        printf 'Refusing to close %s Herdr workspaces for %s\n' "$MATCH_COUNT" "$WORKTREE_PATH" >&2
        exit 1
        ;;
esac
