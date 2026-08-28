#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?usage: post-create.sh REPO WORKTREE_PATH}"
WORKTREE_PATH="${2:?usage: post-create.sh REPO WORKTREE_PATH}"

if [[ "$REPO" == "vintrace-server" ]]; then
    "$HOME/Dropbox/Work/githooks/post-checkout" "$WORKTREE_PATH"
fi
