# Created by newuser for 5.9
# ================================================
# History
# ================================================

HISTFILE="$XDG_STATE_HOME/zsh/History"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# ================================================
# Shell behaviour
# ================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT # sort file10 after file9, not after file1

# ---- Completion ----
# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# SDKMAN: sourced AFTER compinit so its internal bare `compinit` is skipped
# (the guard checks for an existing compdef), avoiding a stray $ZDOTDIR/.zcompdump.
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# NVM completion: also sourced after compinit for the same reason as SDKMAN.
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'


# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

# ---- fzf -------------------
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"
source "$ZDOTDIR/fzf.zsh"

# Aliases
source "$ZDOTDIR/aliases.zsh"

# Custom keybindings
source "$ZDOTDIR/bindings.zsh"

# plugins and plugin manager
source "$ZDOTDIR/plugins.zsh"

# Prompt/theme
source "$ZDOTDIR/prompt.zsh"

eval "$(starship init zsh)"


# ---- worktrunk zsh integration -------------------
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# Fabric setup
source "$ZDOTDIR/fabric.zsh"
