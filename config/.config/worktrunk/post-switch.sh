#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:?usage: post-switch.sh BRANCH WORKTREE_PATH PRIMARY_WORKTREE_PATH}"
WORKTREE_PATH="${2:?usage: post-switch.sh BRANCH WORKTREE_PATH PRIMARY_WORKTREE_PATH}"
PRIMARY_WORKTREE_PATH="${3:?usage: post-switch.sh BRANCH WORKTREE_PATH PRIMARY_WORKTREE_PATH}"

if [[ "${HERDR_ENV:-}" != "1" ]]; then
    printf 'Not running inside Herdr; skipping workspace setup for %s\n' "$WORKTREE_PATH" >&2
    exit 0
fi

if ! command -v herdr >/dev/null 2>&1; then
    printf 'herdr is required to create the workspace\n' >&2
    exit 127
fi

if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required to create the Herdr workspace\n' >&2
    exit 127
fi

# The parent workspace already provides repository context, so keep the
# distinctive final component of the branch as the child workspace label.
WORKSPACE_LABEL="${BRANCH##*/}"

OPEN_RESULT="$(herdr worktree open \
    --cwd "$PRIMARY_WORKTREE_PATH" \
    --path "$WORKTREE_PATH" \
    --label "$WORKSPACE_LABEL" \
    --no-focus)"

WORKSPACE_ID="$(jq -er '.result.workspace.workspace_id' <<<"$OPEN_RESULT")"
AI_TAB_ID="$(jq -er '.result.tab.tab_id' <<<"$OPEN_RESULT")"
AI_PANE_ID="$(jq -er '.result.root_pane.pane_id' <<<"$OPEN_RESULT")"
ALREADY_OPEN="$(jq -r '.result.already_open' <<<"$OPEN_RESULT")"

if [[ "$ALREADY_OPEN" == "true" ]]; then
    herdr workspace focus "$WORKSPACE_ID" >/dev/null
    exit 0
fi

# Keep Claude in the first tab and Neovim in the second tab.
herdr tab rename "$AI_TAB_ID" claude >/dev/null

NVIM_RESULT="$(herdr tab create \
    --workspace "$WORKSPACE_ID" \
    --cwd "$WORKTREE_PATH" \
    --label editor \
    --no-focus)"
NVIM_PANE_ID="$(jq -er '.result.root_pane.pane_id' <<<"$NVIM_RESULT")"

herdr pane run "$AI_PANE_ID" claude >/dev/null
herdr pane run "$NVIM_PANE_ID" nvim >/dev/null

if [[ -f "$WORKTREE_PATH/package.json" ]] && grep -q '"next"' "$WORKTREE_PATH/package.json"; then
    if [[ -f "$PRIMARY_WORKTREE_PATH/.env.local" ]]; then
        cp "$PRIMARY_WORKTREE_PATH/.env.local" "$WORKTREE_PATH/.env.local"
    fi
fi

# The no-focus creation calls leave the Claude tab and AI pane selected.
herdr workspace focus "$WORKSPACE_ID" >/dev/null
