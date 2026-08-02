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
alias ls='eza --icons'

# detailed listing without hidden files
alias ll='eza -lh --icons --git'

# detailed listing with hidden files
alias la='eza -lha --icons --git'

# Tree view
alias tree='eza --tree --icons'

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

# =========== java ===================
alias grbr='gradle bootRun'
alias grbt='gradle build'
alias grbx='gradle build -x test'

alias mvcc='mvn clean compile'
alias mvct='mvn clean test'
alias mvci='mvn clean install -U -DskipTests'
