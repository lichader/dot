#!/bin/bash

# Monitor Hyprland events and fix workspace assignments
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    case "$line" in
        "monitoradded>>HDMI-A-1"|"monitorremoved>>HDMI-A-1")
            echo "Monitor change detected: $line"
            sleep 3  # Give time for monitor to fully initialize

            # Main monitor (DP-1) → workspaces 1–5
            hyprctl dispatch moveworkspacetomonitor 1 DP-1
            hyprctl dispatch moveworkspacetomonitor 2 DP-1
            hyprctl dispatch moveworkspacetomonitor 3 DP-1
            hyprctl dispatch moveworkspacetomonitor 4 DP-1
            hyprctl dispatch moveworkspacetomonitor 5 DP-1

            # Secondary monitor (HDMI-A-1) → workspaces 6–10 (only if monitor is connected)
            if hyprctl monitors | grep -q "HDMI-A-1"; then
                hyprctl dispatch moveworkspacetomonitor 6 HDMI-A-1
                hyprctl dispatch moveworkspacetomonitor 7 HDMI-A-1
                hyprctl dispatch moveworkspacetomonitor 8 HDMI-A-1
                hyprctl dispatch moveworkspacetomonitor 9 HDMI-A-1
                hyprctl dispatch moveworkspacetomonitor 10 HDMI-A-1
            fi
            ;;
    esac
done