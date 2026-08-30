# Arch Hyprland bootstrap

The public [`lichader/dot`](https://github.com/lichader/dot) repository turns a
minimal Arch installation into this Hyprland workstation. It contains the
bootstrap, package manifests, generated system configuration, and portable
desktop, application, and Git configuration, including IdeaVim. Git identity
and work/personal repository routing remain in the separate
`lichader/dot-files` repository and are not required to run the public
bootstrap.

The supported standalone interface is safe to rerun:

```bash
./linux-bootstrap/bootstrap.sh --user lichader
```

Cross-platform applications and CLIs are declared once in the repository-level
[`packages.yaml`](../packages.yaml). The Arch bootstrap installs its Pacman and
AUR mappings in addition to the Arch-only system packages in
[`lib/packages.sh`](lib/packages.sh). Hardware, kernel, Hyprland, and other
Linux-specific packages never enter the shared manifest.

On macOS, after installing Homebrew, install the corresponding formulae and
casks with:

```bash
./macos-bootstrap/install-packages.sh
```

The macOS helper installs `yq` as its manifest-reader bootstrap dependency.

Pass an authenticated checkout of the private repository when its Git package
should also be deployed:

```bash
./linux-bootstrap/bootstrap.sh \
    --user lichader \
    --dotfiles-dir /home/lichader/dot-files
```

The implementation installs only missing packages, checks before cloning or
creating user-scoped tools, replaces generated system configuration only when
its content changes, and uses `systemctl enable` without trying to start
services inside the chroot.

## Minimal installation workflow

Complete Archinstall, then choose its option to chroot into the installed
system. If Archinstall has already returned to the live ISO shell while the
target filesystems remain mounted, enter the new installation manually:

```bash
arch-chroot /mnt
```

Archinstall should already have configured the locale, timezone, hostname,
user, and bootloader. Inside the chroot, remain logged in as root, fetch the
public setup repository over HTTPS, and run the bootstrap:

```bash
pacman -Syu --needed git go-yq
mkdir -p /home/lichader
git clone https://github.com/lichader/dot.git /home/lichader/dot
cd /home/lichader/dot
./linux-bootstrap/bootstrap.sh --user lichader
```

If the user does not exist, the bootstrap creates it, adds it to `wheel`, and
prompts for its login password. A temporary sudo rule allows that non-root user
to install packages through pacman while Paru and makepkg run; the rule is
removed on success or failure.

The public `config` and `git` Stow packages are deployed automatically. The Git
package contains portable behavior and global ignore rules, then includes the
optional `~/.gitconfig.private` and `~/.gitconfig.local` overlays. On Linux,
the bootstrap writes the libsecret credential helper to the untracked local
overlay. It deliberately does not fetch the private repository or handle
GitHub credentials. If an authenticated checkout is already available, place
it somewhere the target user can read (normally `/home/lichader/dot-files`)
and pass it through `--dotfiles-dir`. A checkout created as root beneath the
target user's home is reassigned to that user by the bootstrap, and its Git
package supplies the private identity overlay.

Use a dry run to inspect the planned mutations:

```bash
./linux-bootstrap/bootstrap.sh --user lichader --dry-run
```

Validate shell syntax, manifest invariants, current package availability, and
both forms of the dry-run interface with:

```bash
./linux-bootstrap/check.sh
```

## Post-install login

After rebooting and completing the first graphical login, run the interactive
user-scoped setup without `sudo`:

```bash
./linux-bootstrap/post-install.sh
```

The helper authenticates GitHub through its browser flow, configures GitHub's
credential helper only in the untracked `~/.gitconfig.local`, clones the
private `lichader/dot-files` repository when absent, Stows its private Git
identity overlay, and connects Tailscale. Existing checkouts and authenticated
sessions are reused. Preview the flow or omit Tailscale with:

```bash
./linux-bootstrap/post-install.sh --dry-run
./linux-bootstrap/post-install.sh --skip-tailscale
```

## What it configures

- Full system upgrade, multilib, Git, sudo, Zsh, go-yq, and Paru bootstrap
- System-wide Zsh XDG routing plus persistent completion-cache and history
  directories for the target user
- Linux firmware and AMD CPU/GPU Mesa, Vulkan, VA-API, and monitoring tools
- Hyprland and Noctalia, with Noctalia providing the bar, launcher,
  notifications, wallpaper, clipboard history, idle handling, session lock,
  media controls, network and Bluetooth interfaces, and a polkit agent
- Portals, PipeWire, WirePlumber, screenshots, input methods, and brightness
  controls, including DDC support for external monitors
- Greetd/Tuigreet as the login manager
- GNOME Keyring secret storage, unlocked through the Greetd PAM login using the
  user's login password
- NetworkManager with the iwd backend, Bluetooth, printing, Docker, libvirt,
  LACT, Tailscale, package-cache cleanup, and scheduled services
- Zstd-compressed Zram swap sized to half of system memory with a 16 GiB cap,
  plus virtual-memory tuning for in-memory swap
- GUI, terminal, development, virtualization, gaming, and AUR applications
- Public application, desktop, and portable Git configuration via GNU Stow
- Optional private Git identity and repository routing via a separate overlay
- Herdr with the pinned Vim/Neovim pane-navigation plugin
- Codex and Claude Code from their standalone upstream installers
- NVM with the current Node LTS, SDKMAN with Java/Maven/Gradle, pipx tools, and
  Fabric

`tailscaled.service` is enabled for the first boot, but joining the machine to
a tailnet remains an interactive step performed by the post-install helper:

```bash
./linux-bootstrap/post-install.sh
```

The public bootstrap does not store or consume a Tailscale authentication key.

Sway and KDE/Plasma packages are intentionally excluded. Hardware-specific
Intel, Nouveau, and VMware graphics packages are also excluded from this AMD
workstation profile.

## Trust and reproducibility

Official packages come from configured Arch repositories. AUR packages execute
community-maintained `PKGBUILD` files as the daily user, with review prompts
disabled for automation. Review `packages.yaml`,
`linux-bootstrap/lib/packages.sh`, and `linux-bootstrap/fonts.sh` before running
them on a new machine. Codex, Claude Code, NVM, and SDKMAN use their upstream
installers; existing installations and configured candidates are checked before
rerunning. Codex and Claude authentication remains interactive on first use.

The private repository is an independent trust boundary. This public bootstrap
only reads its Git package when its path is explicitly supplied.
