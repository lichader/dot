#!/bin/bash

# Get active window info
window_info=$(hyprctl activewindow -j)
full_title=$(echo "$window_info" | jq -r '.title')
is_fullscreen=$(echo "$window_info" | jq -r '.fullscreen')

# Handle null or empty title
if [ "$full_title" = "null" ] || [ -z "$full_title" ]; then
    echo "{\"text\": \"\", \"class\": \"empty\"}"
    exit 0
fi

# Truncate title to 10 characters with ellipsis if needed
if [ ${#full_title} -gt 10 ]; then
    title="${full_title:0:10}..."
else
    title="$full_title"
fi

if [ "$is_fullscreen" = "true" ] || [ "$is_fullscreen" = "1" ]; then
    echo "{\"text\": \"󰊓 $title\", \"class\": \"fullscreen\"}"
else
    echo "{\"text\": \"$title\", \"class\": \"normal\"}"
fi
