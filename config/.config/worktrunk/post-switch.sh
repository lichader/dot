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
CODE_TAB_ID="$(jq -er '.result.tab.tab_id' <<<"$OPEN_RESULT")"
AI_PANE_ID="$(jq -er '.result.root_pane.pane_id' <<<"$OPEN_RESULT")"
ALREADY_OPEN="$(jq -r '.result.already_open' <<<"$OPEN_RESULT")"

if [[ "$ALREADY_OPEN" == "true" ]]; then
    herdr workspace focus "$WORKSPACE_ID" >/dev/null
    exit 0
fi

# Layout: Claude (left pane) | Neovim (right pane).
herdr tab rename "$CODE_TAB_ID" code >/dev/null

NVIM_RESULT="$(herdr pane split "$AI_PANE_ID" \
    --direction right \
    --cwd "$WORKTREE_PATH" \
    --no-focus)"
NVIM_PANE_ID="$(jq -er '.result.pane.pane_id' <<<"$NVIM_RESULT")"

DATABASE_RESULT="$(herdr tab create \
    --workspace "$WORKSPACE_ID" \
    --cwd "$WORKTREE_PATH" \
    --label database \
    --no-focus)"
DATABASE_PANE_ID="$(jq -er '.result.root_pane.pane_id' <<<"$DATABASE_RESULT")"

MISC_RESULT="$(herdr tab create \
    --workspace "$WORKSPACE_ID" \
    --cwd "$WORKTREE_PATH" \
    --label misc \
    --no-focus)"
MISC_PANE_ID="$(jq -er '.result.root_pane.pane_id' <<<"$MISC_RESULT")"

herdr pane run "$AI_PANE_ID" claude >/dev/null
herdr pane run "$NVIM_PANE_ID" nvim >/dev/null
herdr pane run "$DATABASE_PANE_ID" "docker ps" >/dev/null

if [[ -f "$WORKTREE_PATH/package.json" ]] && grep -q '"next"' "$WORKTREE_PATH/package.json"; then
    if [[ -f "$PRIMARY_WORKTREE_PATH/.env.local" ]]; then
        cp "$PRIMARY_WORKTREE_PATH/.env.local" "$WORKTREE_PATH/.env.local"
    fi
    herdr pane run "$MISC_PANE_ID" "pnpm install && pnpm dev" >/dev/null
fi

# The no-focus creation calls leave the code tab and AI pane selected.
herdr workspace focus "$WORKSPACE_ID" >/dev/null
