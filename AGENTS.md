# Repository Guidelines

## Project Structure & Module Organization

This repository is a cross-platform dotfiles and workstation bootstrap project.

- `config/` and `git/` are GNU Stow packages. Their paths mirror files deployed into `$HOME`, such as `config/.config/hypr/` and `git/.gitconfig`.
- `linux-bootstrap/` contains the Arch Linux bootstrap, post-install workflow, font installer, validation script, and Linux-only package lists.
- `macos-bootstrap/` contains the Homebrew package installer.
- `packages.yaml` declares applications shared by Arch and macOS; `lib/shared-packages.sh` parses and validates it.
- Desktop assets live beside their owning configuration, for example Hyprland wallpapers and Noctalia scripts under `config/.config/`.

## Build, Test, and Development Commands

There is no compilation step. Use these commands from the repository root:

```bash
./linux-bootstrap/check.sh
./linux-bootstrap/bootstrap.sh --user lichader --dry-run
stow --dir . --target "$HOME" --simulate config git
./macos-bootstrap/install-packages.sh
```

`check.sh` validates shell syntax, runs ShellCheck when available, checks package-manifest invariants, and exercises dry-run workflows. It expects Arch tools for package availability checks. The bootstrap dry run previews system changes. The Stow simulation previews home-directory links. The macOS command performs real Homebrew installations.

## Coding Style & Naming Conventions

Write Bash with strict mode (`set -euo pipefail` or `set -Eeuo pipefail`), four-space indentation, quoted expansions, `snake_case` functions, and uppercase global constants. Keep reusable logic in `lib/`; entry-point scripts should remain orchestration-focused. Use two-space YAML indentation and preserve the `packages.<name>.<platform>` schema. Match the established style in application-owned configuration files, including tab-indented Hyprland Lua.

## Testing Guidelines

No standalone test framework or coverage threshold is used. Run `./linux-bootstrap/check.sh` after changing scripts, package declarations, Git configuration, or bootstrap behavior. Exercise risky workstation changes in a VM and use `--dry-run` first. Manually verify UI changes; include screenshots when Hyprland or Noctalia appearance changes.

## Commit & Pull Request Guidelines

Use the repository's Conventional Commit pattern: `feat(packages): ...`, `fix(fonts): ...`, or `refactor(hyprland): ...`. Keep each commit focused on one logical change and write subjects in the imperative mood. Pull requests should explain the affected platform, user-visible impact, verification performed, and any manual migration steps.

## Security & Local Configuration

Never commit credentials, SSH keys, machine-specific identities, or exported secrets. Keep private Git data in `~/.gitconfig.private` and machine-local overrides in `~/.gitconfig.local`. Review new AUR packages, remote installers, and pinned download hashes before merging.
