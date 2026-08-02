#!/bin/bash

# Get list of sinks (output devices)
sinks=$(pactl list short sinks | awk '{print $2}')

# Show in wofi and get selection
selected=$(echo "$sinks" | wofi --dmenu -p "Select Audio Output" --conf ~/.config/wofi/config --style ~/.config/wofi/style.css)

# If something was selected, set it as default
if [ -n "$selected" ]; then
    pactl set-default-sink "$selected"
fi
