# Arch Hyprland bootstrap

The public [`lichader/dot`](https://github.com/lichader/dot) repository turns a
minimal Arch installation into this Hyprland workstation. It contains the
bootstrap, package manifests, generated system configuration, and desktop
entries. Personal dotfiles remain in the separate private `lichader/dot-files`
repository and are not required to run the public bootstrap.

The supported standalone interface is safe to rerun:

```bash
./setup/bootstrap.sh --user lichader
```

Pass an authenticated checkout of the private repository when personal
dotfiles should also be deployed:

```bash
./setup/bootstrap.sh \
    --user lichader \
    --dotfiles-dir /home/lichader/dot-files
```

The implementation installs only missing packages, checks before cloning or
creating user-scoped tools, replaces generated system configuration only when
its content changes, and uses `systemctl enable` without trying to start
services inside the chroot.

## Minimal installation workflow

Complete the normal Arch installation through mounting the target filesystems,
installing `base`, a kernel, firmware, generating `fstab`, and entering the new
installation:

```bash
arch-chroot /mnt
```

Configure the locale, timezone, hostname, root password, and bootloader as part
of the base Arch installation. Then fetch the public setup repository over
HTTPS and run the bootstrap as root:

```bash
pacman -Syu --needed git
mkdir -p /home/lichader
git clone https://github.com/lichader/dot.git /home/lichader/dot
cd /home/lichader/dot
./setup/bootstrap.sh --user lichader
```

If the user does not exist, the bootstrap creates it, adds it to `wheel`, and
prompts for its login password. A temporary sudo rule allows that non-root user
to install packages through pacman while Paru and makepkg run; the rule is
removed on success or failure.

The public bootstrap deliberately does not fetch the private repository or
handle GitHub credentials. If an authenticated checkout is already available,
place it somewhere the target user can read (normally
`/home/lichader/dot-files`) and pass it through `--dotfiles-dir`. A checkout
created as root beneath the target user's home is reassigned to that user by
the bootstrap.

Use a dry run to inspect the planned mutations:

```bash
./setup/bootstrap.sh --user lichader --dry-run
```

Validate shell syntax, manifest invariants, current package availability, and
both forms of the dry-run interface with:

```bash
./setup/check.sh
```

## What it configures

- Full system upgrade, multilib, Git, sudo, Zsh, and Paru bootstrap
- Linux firmware and AMD CPU/GPU Mesa, Vulkan, VA-API, and monitoring tools
- Hyprland, portals, PipeWire, WirePlumber, notifications, launcher, lock and
  idle tools, screenshots, clipboard history, input methods, and a polkit agent
- Greetd/Tuigreet as the login manager
- GNOME Keyring secret storage, unlocked through the Greetd PAM login using the
  user's login password
- NetworkManager with the iwd backend, Bluetooth, printing, Docker, libvirt,
  LACT, package-cache cleanup, and scheduled services
- GUI, terminal, development, virtualization, gaming, and AUR applications
- Optional private dotfiles via GNU Stow
- NVM with the current Node LTS, SDKMAN with Java/Maven/Gradle, pipx tools, and
  Fabric

Sway and KDE/Plasma packages are intentionally excluded. Hardware-specific
Intel, Nouveau, and VMware graphics packages are also excluded from this AMD
workstation profile.

## Trust and reproducibility

Official packages come from configured Arch repositories. AUR packages execute
community-maintained `PKGBUILD` files as the daily user, with review prompts
disabled for automation. Review `setup/lib/packages.sh` and `setup/fonts.sh`
before running them on a new machine. NVM and SDKMAN use their upstream
installers; their bootstrap versions and installed candidates are checked
before rerunning.

The private dotfiles repository is an independent trust boundary. This public
bootstrap only reads it when its path is explicitly supplied.
