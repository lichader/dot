#!/usr/bin/env bash
REPO="$1"
WORKTREE_PATH="$2"

if [ "$REPO" = "vintrace-server" ]; then
    "$HOME/Dropbox/Work/githooks/post-checkout" "$WORKTREE_PATH"
fi
