# Workstation setup context

This document records the decisions and operating assumptions for the public
workstation bootstrap in [`lichader/dot`](https://github.com/lichader/dot) as of
2026-08-28. It is context for future maintenance, not a replacement for the
runnable instructions in [`README.md`](README.md).

## Goal

The public repository should turn a minimal, vanilla Arch Linux installation
into the workstation's Arch and Hyprland foundation with one repeatable
command. The public `config` and `git` Stow packages supply the Linux desktop,
shared application configuration, portable Git behavior, and global ignore
rules, including IdeaVim's XDG configuration. Git identity and repository
routing remain in the separate `lichader/post-setup-config` repository and can
be deployed from an authenticated local checkout. The public bootstrap does
not fetch that repository or manage GitHub credentials.

`linux-bootstrap/bootstrap.sh` intentionally supports Arch Linux only. The
public config package may contain cross-platform and macOS application settings,
but the Linux bootstrap excludes macOS-only configuration while Stowing it.

The active Linux desktop stack is Hyprland. Sway, KDE/Plasma, SDDM, and their
related package/configuration sets are intentionally excluded.

## Repository boundary

The two repositories have distinct responsibilities:

- `lichader/dot` is public. It owns the bootstrap scripts, package manifests,
  generated system configuration, validation, wallpapers, and the `config`
  and `git` Stow packages for portable shell, desktop, editor, application, and
  Git configuration.
- `lichader/post-setup-config` is private. It retains Git identity,
  work/personal repository routing, and any configuration that should not be
  published.

The public bootstrap always Stows its local `config` and `git` packages. The
public Git configuration includes `~/.gitconfig.private` for identity and
repository routing plus `~/.gitconfig.local` for machine-specific settings.
The Linux bootstrap writes its libsecret credential helper to the local file.
Supplying `--dotfiles-dir PATH` additionally Stows the private Git overlay. The
path must already exist and be readable; the bootstrap deliberately performs
no authenticated clone.

## Installation workflow

Complete the normal base installation from the Arch ISO first: mount the target
filesystems, install the base system, generate `fstab`, and configure the
timezone, locale, hostname, credentials, kernel, firmware, and bootloader. Then
enter the installed system as root:

```bash
arch-chroot /mnt
```

Clone the public setup repository beneath the daily user's future home, even
when cloning as root:

```bash
pacman -Syu --needed git go-yq
mkdir -p /home/lichader
git clone https://github.com/lichader/dot.git /home/lichader/dot
cd /home/lichader/dot
./linux-bootstrap/bootstrap.sh --user lichader
```

For the maintainer's personalized installation, first make an authenticated
checkout of the private repository available, then pass it explicitly:

```bash
./linux-bootstrap/bootstrap.sh \
    --user lichader \
    --dotfiles-dir /home/lichader/post-setup-config
```

Running the bootstrap as root inside `arch-chroot` is required and expected.
Always pass the intended daily account with `--user`; root must not become the
desktop account. A dry run is available before making changes:

```bash
./linux-bootstrap/bootstrap.sh --user lichader --dry-run
```

If either repository was cloned as root beneath the target user's home, the
bootstrap corrects its ownership. A checkout under `/root` is not supported for
private dotfile deployment because the target user must be able to read it.

## Privilege boundary

System work runs as root:

- Full system upgrade and official package installation with pacman
- `/etc` configuration, including the system Zsh XDG routing, user/group
  membership, and service enablement
- Greetd, networking, graphics, Zram, sudo, Docker, and libvirt configuration

User-scoped work runs as the account passed through `--user`:

- Building Paru and AUR packages
- Stowing the public config and Git packages plus optional private Git identity
- Installing Codex, Claude Code, and Fabric with their standalone upstream
  installers, plus NVM, Node LTS, SDKMAN candidates, pipx tools, GitHub Copilot
  CLI, and the pinned Herdr navigation plugin
- Updating user directories and fonts

After the first graphical login, `post-install.sh` runs as the daily user. It
owns the interactive Tailscale connection, browser-based GitHub authentication,
the private post-setup checkout, and Git overlay deployment, in that order.
These steps do not run inside the chroot because they depend on a user session
and external authentication.

After the first normal boot, `post-check.sh` provides a read-only validation of
the expected EFI partition, Btrfs subvolume mounts and Zstd compression, the
disk-backed swap partition, and Zram. It reports deviations and exits nonzero
without modifying the installed system.

A temporary sudoers rule permits the target user to invoke only pacman while
the bootstrap is active so Paru and makepkg can install packages. The rule is
removed on both successful and failed exits. Services are enabled without
`--now` because systemd is not normally PID 1 inside the installation chroot.
They start after reboot.

## Desktop and hardware profile

The strict cross-platform package intersection lives in the repository-level
`packages.yaml`: every entry must have both an Arch mapping and a Homebrew
formula or cask mapping. `linux-bootstrap/lib/packages.sh` contains only the
Arch bootstrap, hardware, desktop, and other Linux-specific packages. The Arch
bootstrap combines both manifests at installation time. Font packages and
their reviewed fallback logic live in `linux-bootstrap/fonts.sh`. Together they
include:

- AMD microcode, Mesa, Radeon Vulkan/VA-API support, and monitoring tools
- Hyprland, Noctalia, portals, UWSM, screenshot tools, and input methods
- Nautilus as the graphical file manager and default directory handler on
  `Super+Shift+E`, terminal Yazi on `Super+E`, and the required GVfs filesystem
  integrations
- GNOME Image Viewer as the default application for common image formats
- PipeWire/WirePlumber, NetworkManager with iwd, Bluetooth, printing, Docker,
  libvirt, Tailscale, gaming packages, and workstation applications
- Zsh, Paru, Neovim, Herdr, development tools, fonts, and user-scoped language
  tools

Sway and KDE package names are rejected by `linux-bootstrap/check.sh`.
Hardware-specific Intel, Nouveau, and VMware graphics packages are outside this
profile.

## Compressed swap

`zram-generator` creates `/dev/zram0` as swap during the first normal boot; the
bootstrap does not add it to `fstab` or enable a persistent service. The logical
device uses Zstd, is sized to half of physical memory with a 16 GiB cap, and has
swap priority 100. The allocation grows only as compressed pages are stored.

The bootstrap also writes `/etc/sysctl.d/99-zram.conf` with swappiness 150 so
the kernel prefers inexpensive in-memory swap over reclaiming useful file
cache, and page-cluster 0 to disable swap readahead. Zram is volatile and does
not provide a hibernation target; hibernation would require separate
disk-backed swap.

## Tailscale

The official `tailscale` package is installed and `tailscaled.service` is
enabled for the first normal boot. The user-scoped post-install helper invokes
`sudo tailscale up` when the workstation is not already connected. Reusable
authentication keys are secrets and must not be stored in this public
repository.

## Login manager

Greetd with [tuigreet](https://github.com/apognu/tuigreet) is used instead of
SDDM. The bootstrap installs the official `greetd` and `greetd-tuigreet` Arch
packages, enables `greetd.service`, creates `/var/cache/tuigreet` with the
correct ownership, and generates `/etc/greetd/config.toml`.

Tuigreet lists sessions from `/usr/share/wayland-sessions`, remembers the last
username, and remembers the selected session per user. On the first login,
select Hyprland from the session menu with `F3`. Keeping the selector provides a
recovery path instead of hardcoding Hyprland. Automatic login is not enabled.

## Noctalia and encrypted secrets

Noctalia owns the desktop shell layer: bar, launcher, notifications, wallpaper,
clipboard history, media and brightness controls, idle handling, session lock,
session actions, NetworkManager and Bluetooth interfaces, and the graphical
polkit agent. The corresponding standalone shell applications are deliberately
excluded from the package manifest and public configuration.

The workstation defaults to dark appearance without locking that preference:
Noctalia starts in dark mode, Dconf provides `prefer-dark` and the packaged
`adw-gtk3-dark` theme as user-overridable system defaults, static GTK settings
cover applications that do not consult Dconf, and Kvantum supplies the packaged
`KvGnomeDark` style to Qt 5 and Qt 6 applications.

Noctalia's session lock and application secret storage are separate:

- `gnome-keyring` supplies the Secret Service backend and PAM module;
  `libsecret` supplies the client API used by applications.
- The bootstrap generates `/etc/pam.d/greetd` with
  `pam_gnome_keyring.so` authentication and `auto_start` session hooks.
- The public Hyprland autostart completes initialization of the keyring daemon's
  `secrets` component after the graphical session and D-Bus are available.
- Noctalia supplies the NetworkManager secret agent and stores credentials
  through the Secret Service backend, so Wi-Fi passwords remain encrypted and
  available after login.

The GNOME login keyring password should match the Linux login password so the
tuigreet login unlocks it automatically. KDE Wallet is not installed or needed.

## Idempotency expectations

`linux-bootstrap/bootstrap.sh` is designed to be safe to rerun:

- Pacman and Paru use `--needed`.
- Existing users, Paru, SDKMAN, NVM, Codex, Claude Code, Fabric, pipx packages,
  and user tools are detected.
- The post-install helper reuses authenticated GitHub sessions and existing
  private checkouts, and skips Tailscale when it is already connected.
- Machine-local Git settings live in the untracked `~/.gitconfig.local`;
  identity and repository routing live in the separately Stowed
  `~/.gitconfig.private`.
- Generated system files are replaced only when their content differs.
- Services are enabled only when not already enabled.
- Stow uses `--restow` for the public config, public Git, and supplied private
  packages.
- Temporary build directories and sudo rules are cleaned on exit.

The bootstrap may still stop on a genuine conflict, such as an existing user
file that GNU Stow cannot safely replace or an unavailable/failed AUR build.

## Cross-platform configuration

Tracked public configuration must not contain machine-specific home paths when
a portable alternative exists. The Linux bootstrap excludes macOS-only config
directories from Stow, wallpapers use home-relative paths, and generated Zsh
completion dumps and backup Hyprland configuration are ignored.

The public Git package must remain free of identity, credential helpers, and
repository-specific include conditions. The bootstrap must refer to the
private checkout only through the path supplied with `--dotfiles-dir`; it must
not duplicate or publish private Git configuration.

## Security and repository hygiene

Do not commit credentials, tokens, private keys, private hostnames, generated
machine state, private dotfiles, or local agent configuration to this public
repository. Public wallpapers must be checked for sensitive metadata before
they are committed.

AUR packages execute community-maintained `PKGBUILD` files. The Arch mappings
in `packages.yaml`, the Arch-only AUR manifest in
`linux-bootstrap/lib/packages.sh`, and the font-specific AUR handling in
`linux-bootstrap/fonts.sh` should all remain explicit and reviewable.

The private checkout is trusted input. The public bootstrap validates its
expected Git Stow package structure but does not audit or publish its contents.

## Validation

Before committing public setup changes, run:

```bash
./linux-bootstrap/check.sh
git diff --check
```

`linux-bootstrap/check.sh` validates shell syntax, runs ShellCheck when
available, checks the shared and Arch-only package-list invariants and official
package availability, checks AUR availability when Paru is installed, validates
that the public Git package contains no private keys, verifies the essential
Zsh/XDG setup, and exercises dry runs with and without a private configuration
directory. `linux-bootstrap/post-check.sh` separately validates the live
storage layout after boot and is not executed by the repository test suite.

For public Neovim changes, also run:

```bash
nvim --headless -u config/.config/nvim/init.lua +qa
```
