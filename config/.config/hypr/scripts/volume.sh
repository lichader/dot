#!/bin/bash

# Volume control script with macOS-style notifications

case "$1" in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac

# Get current volume and mute status
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "yes" || echo "no")

# Choose icon based on volume level and mute status
if [ "$muted" = "yes" ]; then
    icon="audio-volume-muted"
    text="Muted"
elif [ "$volume" -eq 0 ]; then
    icon="audio-volume-muted"
    text="Volume: ${volume}%"
elif [ "$volume" -lt 33 ]; then
    icon="audio-volume-low"
    text="Volume: ${volume}%"
elif [ "$volume" -lt 66 ]; then
    icon="audio-volume-medium"
    text="Volume: ${volume}%"
else
    icon="audio-volume-high"
    text="Volume: ${volume}%"
fi

# Send notification with progress bar
# -h int:value:X shows a progress bar at X%
# -h string:x-canonical-private-synchronous:volume replaces previous volume notifications
notify-send -h int:value:$volume \
            -h string:x-canonical-private-synchronous:volume \
            -i "$icon" \
            "Volume" "$text"
