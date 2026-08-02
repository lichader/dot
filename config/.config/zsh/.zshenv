# ~/.config/zsh/.zshenv


#  -------- XDG base directories --------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

#  -------- Editor --------
export EDITOR="nvim"
export VISUAL="nvim"

#  -------- GPG --------
export GPG_TTY=$(tty)


# --------- dev tools --------
export PNPM_HOME="$HOME/.local/share/pnpm"

export SDKMAN_DIR="$HOME/.sdkman"

# zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export M2_HOME="$HOME/.sdkman/candidates/maven/current"
export GRADLE_HOME="$HOME/.sdkman/candidates/gradle/current"

export K9S_CONFIG_DIR="$HOME/.config/k9s"

[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
export CARGO_HOME="$HOME/.cargo"

export GOPATH="$HOME/go"

# --------- PATH -------
export PATH="$HOME/.local/bin:$PNPM_HOME:$CARGO_HOME/bin:$GOPATH/bin:$PATH"

# --------- Starship -----
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"
