#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/colors.sh" # Loads all defined colors

sid="$1"
focused_workspace="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

if [ "$sid" = "$focused_workspace" ]; then
  sketchybar --set "$NAME" drawing=on \
                           background.drawing=on \
                           background.color="$ACCENT_COLOR" \
                           label.color="$BAR_COLOR" \
                           icon.color="$BAR_COLOR"
else
  sketchybar --set "$NAME" drawing=on \
                           background.drawing=off \
                           label.color="$ACCENT_COLOR" \
                           icon.color="$ACCENT_COLOR"
fi
