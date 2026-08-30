# dot

Cross-platform dotfiles and bootstrap scripts for an Arch Linux Hyprland/Noctalia workstation and macOS. Shared applications are declared once, while platform-specific packages and system configuration remain separate.

## Repository layout

- `config/` — application configuration deployed with GNU Stow
- `git/` — portable Git configuration and global ignore rules
- `packages.yaml` — applications shared between Arch and macOS
- `linux-bootstrap/` — repeatable Arch installation and post-install scripts
- `macos-bootstrap/` — Homebrew formula and cask installer

## Getting started

For a new Arch installation, follow [linux-bootstrap/README.md](linux-bootstrap/README.md). Preview the bootstrap before applying it:

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
