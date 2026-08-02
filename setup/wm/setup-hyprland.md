# Hyprland setup

Hyprland is installed and configured by [`../bootstrap.sh`](../bootstrap.sh).
The package manifest includes the compositor, portals, session utilities,
PipeWire/WirePlumber, AMD graphics support, and the workstation's desktop
utilities. Personal Hyprland, Waybar, Wofi, and lock-screen configuration lives
in the private `lichader/dot-files` repository and is deployed only when its
checkout is passed through `--dotfiles-dir`.

Run the full setup from the repository root as described in
[`../README.md`](../README.md).
