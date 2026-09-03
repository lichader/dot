#!/bin/bash

set -euo pipefail

sketchybar --add event aerospace_workspace_change
while IFS=: read -r sid display_id; do
    sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change front_app_switched \
        --set space.$sid \
        display="$display_id" \
        background.color=0x44ffffff \
        background.corner_radius=5 \
        background.height=20 \
        background.drawing=off \
        label="$sid" \
        click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done < <(aerospace list-workspaces --all \
    --format '%{workspace}:%{monitor-appkit-nsscreen-screens-id}')
