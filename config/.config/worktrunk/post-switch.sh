#!/usr/bin/env bash
BRANCH="$1"
WORKTREE_PATH="$2"

REPO_NAME="$(basename "$(dirname "$(git -C "$WORKTREE_PATH" rev-parse --git-common-dir)")")"
PARENT_FOLDER="$(basename "$(dirname "$WORKTREE_PATH")")"

# If branch has a slash, use part after first slash; otherwise use full branch name
if [[ "$BRANCH" == *"/"* ]]; then
    BRANCH_NAME="${BRANCH#*/}"
else
    BRANCH_NAME="$BRANCH"
fi

# Truncate branch part to 20 chars, then prefix with repo name
BRANCH_NAME="${BRANCH_NAME:0:20}"
SESSION_NAME="${REPO_NAME} - ${BRANCH_NAME}"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux switch-client -t "$SESSION_NAME"
else
    # Determine AI command based on parent folder
    case "$PARENT_FOLDER" in
        rpeng)    AI_CMD="codex" ;;
        vintrace) AI_CMD="claude --dangerously-skip-permissions" ;;
    esac

    # Create new detached session with first window "code"
    # Layout: AI tool (full left pane) | neovim (top right) / lazygit (bottom right)
    tmux new-session -d -s "$SESSION_NAME" -n "code" -c "$WORKTREE_PATH"
    tmux send-keys -t "$SESSION_NAME:code" "$AI_CMD" Enter
    tmux split-window -t "$SESSION_NAME:code" -h -p 70 -c "$WORKTREE_PATH"
    tmux send-keys -t "$SESSION_NAME:code" "nvim" Enter
    tmux split-window -t "$SESSION_NAME:code" -v -c "$WORKTREE_PATH"
    tmux send-keys -t "$SESSION_NAME:code" "lazygit" Enter

    # Second window "database" — runs docker ps
    tmux new-window -t "$SESSION_NAME" -n "database" -c "$WORKTREE_PATH"
    tmux send-keys -t "$SESSION_NAME:database" "docker ps" Enter

    # Fourth window "misc"
    tmux new-window -t "$SESSION_NAME" -n "misc" -c "$WORKTREE_PATH"
    if [ -f "$WORKTREE_PATH/package.json" ] && grep -q '"next"' "$WORKTREE_PATH/package.json"; then
        SOURCE_REPO="$(dirname "$(git -C "$WORKTREE_PATH" rev-parse --git-common-dir)")"
        if [ -f "$SOURCE_REPO/.env.local" ]; then
            cp "$SOURCE_REPO/.env.local" "$WORKTREE_PATH/.env.local"
        fi
        tmux send-keys -t "$SESSION_NAME:misc" "pnpm install && pnpm dev" Enter
    fi

    # Focus the AI pane (left) and switch to session
    tmux select-pane -t "$SESSION_NAME:code.0"
    tmux switch-client -t "$SESSION_NAME:code"
fi
