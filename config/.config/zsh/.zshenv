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

# Android SDK (only where it is installed). AVD home is pinned because
# XDG_CONFIG_HOME makes avdmanager write to ~/.config/.android/avd, while the
# emulator only reads ~/.android/avd.
if [[ -d "$HOME/Android/Sdk" ]]; then
	export ANDROID_HOME="$HOME/Android/Sdk"
	export ANDROID_AVD_HOME="$HOME/.android/avd"
fi

# --------- PATH -------
export PATH="$HOME/.local/bin:$PNPM_HOME:$CARGO_HOME/bin:$GOPATH/bin:$PATH"
# SDK platform-tools comes before /usr/bin so its adb wins over Arch's
# android-tools adb; mixing the two makes them restart each other's server.
if [[ -n "${ANDROID_HOME:-}" ]]; then
	export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
fi

# --------- Starship -----
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# --------- gh --------
# Use the personal GitHub account inside personal folders; elsewhere use the
# account selected with `gh auth switch`.
# Defined here rather than in aliases.zsh so non-interactive shells (scripts,
# editor and agent tooling) get it too.
GH_PERSONAL_USER='lichader'
GH_PERSONAL_DIRS=("$HOME/Developer/rpeng" "$HOME/dot")

function gh() {
	local dir token
	for dir in "${GH_PERSONAL_DIRS[@]}"; do
		if [[ "$PWD/" == "$dir/"* ]]; then
			token="$(command gh auth token --user "$GH_PERSONAL_USER")" || return
			GH_TOKEN="$token" command gh "$@"
			return
		fi
	done
	command gh "$@"
}
