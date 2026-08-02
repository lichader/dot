#!/usr/bin/env bash
BRANCH="$1"
REPO_NAME="$(basename "$2")"

# If branch has a slash, use part after first slash; otherwise use full branch name
if [[ "$BRANCH" == *"/"* ]]; then
    BRANCH_NAME="${BRANCH#*/}"
else
    BRANCH_NAME="$BRANCH"
fi

# Truncate branch part to 20 chars, then prefix with repo name
BRANCH_NAME="${BRANCH_NAME:0:20}"
SESSION_NAME="${REPO_NAME} - ${BRANCH_NAME}"

if [ -n "$TMUX" ] && tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux kill-session -t "$SESSION_NAME"
fi
