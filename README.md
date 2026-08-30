# dot

Cross-platform dotfiles and bootstrap scripts for an Arch Linux Hyprland/Noctalia workstation and macOS. Shared applications are declared once, while platform-specific packages and system configuration remain separate.

## Repository layout

- `config/` — application configuration deployed with GNU Stow
- `git/` — portable Git configuration and global ignore rules
- `packages.yaml` — applications shared between Arch and macOS
- `linux-bootstrap/` — repeatable Arch installation and post-install scripts
- `macos-bootstrap/` — Homebrew formula and cask installer

## Fresh Arch installation

After Archinstall finishes, choose its option to chroot into the installed
system. If you have already returned to the Arch ISO shell, enter it manually:

```bash
arch-chroot /mnt
```

Inside the chroot, remain logged in as root and clone this public repository
over HTTPS:

```bash
pacman -Syu --needed git go-yq
mkdir -p /home/lichader
git clone https://github.com/lichader/dot.git /home/lichader/dot
cd /home/lichader/dot
./linux-bootstrap/bootstrap.sh --user lichader
```

The bootstrap configures the existing Archinstall user, installs the
workstation, and transfers ownership of the checkout. Exit the chroot and
reboot from the live environment:

```bash
exit
reboot
```

After the first graphical login, run the user-scoped setup without `sudo`:

```bash
cd ~/dot
./linux-bootstrap/post-install.sh
```

This final step authenticates GitHub, retrieves the private dotfiles, and
connects Tailscale. Private SSH keys are not required to run the public
bootstrap. See [linux-bootstrap/README.md](linux-bootstrap/README.md) for the
full workflow.

Preview the bootstrap before applying it:

```bash
./linux-bootstrap/bootstrap.sh --user lichader --dry-run
```

On macOS, install Homebrew and then run:

```bash
./macos-bootstrap/install-packages.sh
```

To preview deployment of only the public dotfiles:

```bash
stow --dir . --target "$HOME" --simulate config git
```

Validate bootstrap scripts and package manifests on Arch with:

```bash
./linux-bootstrap/check.sh
```

Private identities, credentials, SSH keys, and machine-local Git settings are intentionally excluded from this repository.
