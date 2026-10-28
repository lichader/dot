# yazi quick shortcut
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

alias n='nvim'
compdef nvim=vim

# =========== eza ==================
# default ls with icons
alias ls='eza --icons=auto'

# detailed listing without hidden files
alias ll='eza -lh --icons=auto --git'

# detailed listing with hidden files
alias la='eza -lha --icons=auto --git'

# Tree view
alias tree='eza --tree --icons=auto'

# make zsh completion to use eza instead of ls
compdef eza=ls

# =========== bat ==================
alias cat='bat'
compdef bat=cat     # bat is cat-compatible

# =========== ripgrep ==================
alias grep='rg --color=auto'

# Go back to the last location
alias -- '-'='cd -'

# Oh My Zsh-style parent directory shortcuts
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias top=btop
alias lg=lazygit
alias ff=fastfetch
alias cod='codex --yolo'
alias cop='copilot --yolo'

# =========== git ====================
# Common Oh My Zsh Git shortcuts
alias g='git'
alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'

alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gc='git commit --verbose'
alias gcmsg='git commit --message'
alias gcam='git commit --all --message'
alias gc!='git commit --verbose --amend'
alias gcn!='git commit --verbose --no-edit --amend'

alias gd='git diff'
alias gdca='git diff --cached'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch --create'

alias gcl='git clone --recurse-submodules'
alias gf='git fetch'
alias gl='git pull'
alias gpr='git pull --rebase'
alias gp='git push'
alias gpd='git push --dry-run'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'

alias gm='git merge'
alias gma='git merge --abort'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grh='git reset'
alias grs='git restore'
alias grst='git restore --staged'

alias gsta='git stash push'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gstaa='git stash apply'
alias gsts='git stash show --patch'
alias grv='git remote --verbose'
alias gsh='git show'

# =========== paru ===================
alias psu='paru -Syu'
alias psi='paru -S'

# =========== java ===================
alias grbr='gradle bootRun'
alias grbt='gradle build'
alias grbx='gradle build -x test'

# Prefer the Maven wrapper in the current directory.
function mvn() {
	if [[ -f ./mvnw ]]; then
		./mvnw "$@"
	else
		command mvn "$@"
	fi
}

alias mvcc='mvn clean compile'
alias mvct='mvn clean test'
alias mvci='mvn clean install -U -DskipTests'
