# Workstation setup context

This document records the decisions and operating assumptions for the public
workstation bootstrap in [`lichader/dot`](https://github.com/lichader/dot) as of
2026-08-02. It is context for future maintenance, not a replacement for the
runnable instructions in [`README.md`](README.md).

## Goal

The public repository should turn a minimal, vanilla Arch Linux installation
into the workstation's Arch and Hyprland foundation with one repeatable
command. Personal configuration is kept in the separate private
`lichader/dot-files` repository and can be deployed from an authenticated local
checkout. The public bootstrap does not fetch that repository or manage GitHub
credentials.

`setup/bootstrap.sh` intentionally supports Arch Linux only. Cross-platform and
macOS dotfiles belong to the private repository rather than this public setup
repository.

The active Linux desktop stack is Hyprland. Sway, KDE/Plasma, SDDM, and their
related package/configuration sets are intentionally excluded.

## Repository boundary

The two repositories have distinct responsibilities:

- `lichader/dot` is public. It owns the bootstrap scripts, package manifests,
  generated system configuration, validation, and non-secret desktop entries.
- `lichader/dot-files` is private. It owns personal Stow packages, application
  configuration, shell and Git configuration, wallpapers, and macOS support.

The public bootstrap works without the private repository. Supplying
`--dotfiles-dir PATH` opts into Stowing the `config`, `git`, and `ideavim`
packages from that checkout. The path must already exist and be readable; the
bootstrap deliberately performs no authenticated clone.

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
pacman -Syu --needed git
mkdir -p /home/lichader
git clone https://github.com/lichader/dot.git /home/lichader/dot
cd /home/lichader/dot
./setup/bootstrap.sh --user lichader
```

For the maintainer's personalized installation, first make an authenticated
checkout of the private repository available, then pass it explicitly:

```bash
./setup/bootstrap.sh \
    --user lichader \
    --dotfiles-dir /home/lichader/dot-files
```

Running the bootstrap as root inside `arch-chroot` is required and expected.
Always pass the intended daily account with `--user`; root must not become the
desktop account. A dry run is available before making changes:

```bash
./setup/bootstrap.sh --user lichader --dry-run
```

If either repository was cloned as root beneath the target user's home, the
bootstrap corrects its ownership. A checkout under `/root` is not supported for
private dotfile deployment because the target user must be able to read it.

## Privilege boundary

System work runs as root:

- Full system upgrade and official package installation with pacman
- `/etc` configuration, user/group membership, and service enablement
- Greetd, networking, graphics, Zram, sudo, Docker, and libvirt configuration

User-scoped work runs as the account passed through `--user`:

- Building Paru and AUR packages
- Stowing private dotfiles when `--dotfiles-dir` is supplied
- Installing NVM, Node LTS, SDKMAN candidates, pipx tools, Fabric, Codex, and
  GitHub Copilot CLI
- Updating user directories and fonts

A temporary sudoers rule permits the target user to invoke only pacman while
the bootstrap is active so Paru and makepkg can install packages. The rule is
removed on both successful and failed exits. Services are enabled without
`--now` because systemd is not normally PID 1 inside the installation chroot.
They start after reboot.

## Desktop and hardware profile

The main package manifest is organized by concern in `setup/lib/packages.sh`
and targets an AMD workstation. Font packages and their reviewed fallback logic
live in `setup/fonts.sh`. Together they include:

- AMD microcode, Mesa, Radeon Vulkan/VA-API support, and monitoring tools
- Hyprland, Hyprlock, Hypridle, Hyprpaper, Waybar, Wofi, portals, and UWSM
- PipeWire/WirePlumber, NetworkManager with iwd, Bluetooth, printing, a polkit
  agent, Docker, libvirt, gaming packages, and workstation applications
- Zsh, Paru, Neovim, development tools, fonts, and user-scoped language tools

Sway and KDE package names are rejected by `setup/check.sh`. Hardware-specific
Intel, Nouveau, and VMware graphics packages are outside this profile.

## Login manager

Greetd with [tuigreet](https://github.com/apognu/tuigreet) is used instead of
SDDM. The bootstrap installs the official `greetd` and `greetd-tuigreet` Arch
packages, enables `greetd.service`, creates `/var/cache/tuigreet` with the
correct ownership, and generates `/etc/greetd/config.toml`.

Tuigreet lists sessions from `/usr/share/wayland-sessions`, remembers the last
username, and remembers the selected session per user. On the first login,
select Hyprland from the session menu with `F3`. Keeping the selector provides a
recovery path instead of hardcoding Hyprland. Automatic login is not enabled.

## Hyprlock and encrypted secrets

Hyprlock password authentication and application secret storage are separate:

- The official Arch `hyprlock` package supplies `/etc/pam.d/hyprlock` and uses
  the normal PAM login stack. Hyprlock does not require a desktop wallet.
- `gnome-keyring` supplies the Secret Service backend and PAM module;
  `libsecret` supplies the client API used by applications.
- The bootstrap generates `/etc/pam.d/greetd` with
  `pam_gnome_keyring.so` authentication and `auto_start` session hooks.
- When the private dotfiles are deployed, their Hyprland autostart completes
  initialization of the keyring daemon's `secrets` component after the
  graphical session and D-Bus are available.

The GNOME login keyring password should match the Linux login password so the
tuigreet login unlocks it automatically. KDE Wallet is not installed or needed.

## Idempotency expectations

`setup/bootstrap.sh` is designed to be safe to rerun:

- Pacman and Paru use `--needed`.
- Existing users, Paru, SDKMAN, NVM, pipx packages, and user tools are detected.
- The private Git configuration is included only when it is supplied and the
  include is absent.
- Generated system files are replaced only when their content differs.
- Services are enabled only when not already enabled.
- Stow uses `--restow` for explicitly supplied private dotfile packages.
- Temporary build directories and sudo rules are cleaned on exit.

The bootstrap may still stop on a genuine conflict, such as an existing user
file that GNU Stow cannot safely replace or an unavailable/failed AUR build.

## Private configuration portability

Machine-specific home paths, macOS configuration, wallpapers, and generated Zsh
completion dumps are concerns of the private repository. The public bootstrap
must refer to the private checkout only through the path supplied with
`--dotfiles-dir`; it must not duplicate or publish private configuration.

## Security and repository hygiene

Do not commit credentials, tokens, private keys, private hostnames, generated
machine state, private dotfiles, wallpapers, or local agent configuration to
this public repository.

AUR packages execute community-maintained `PKGBUILD` files. The main AUR
manifest in `setup/lib/packages.sh` and the font-specific AUR handling in
`setup/fonts.sh` should both remain explicit and reviewable.

The private dotfiles checkout is trusted input. The public bootstrap validates
its expected Stow package structure but does not audit or publish its contents.

## Validation

Before committing public setup changes, run:

```bash
./setup/check.sh
git diff --check
```

`setup/check.sh` validates shell syntax, runs ShellCheck when available, checks
package-list invariants and official package availability, checks AUR
availability when Paru is installed, and exercises dry runs with and without a
private dotfiles directory.

Private Neovim configuration should be validated from an authenticated checkout
of `lichader/dot-files`; it is not part of this repository's public validation.
