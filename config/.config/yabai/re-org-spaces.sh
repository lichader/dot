#!/bin/bash
#
# Use jq to parse the JSON array and read it into a Bash array
displays=()
while IFS= read -r line; do
    displays+=("$line")
done < <(yabai -m query --displays | jq '.[].index')
size=${#displays[@]}
echo "Size of displays: ${size}"

spaces=()
while IFS= read -r line; do
    spaces+=("$line")
done < <(yabai -m query --spaces | jq '.[].index')
size_spaces=${#spaces[@]}
echo "Size of spaces: ${size_spaces}"

function handle_one_display {
    echo "Re organise the spaces for single display"
    yabai -m space --destroy 9
    yabai -m space --destroy 8
    yabai -m space --destroy 7
    yabai -m space --destroy 6

    echo "Create new spaces in second displays"
    # space 6
    yabai -m space --create 1
    # space 7
    yabai -m space --create 1
    # space 8
    yabai -m space --create 1
    # space 9
    yabai -m space --create 1

    yabai --restart-service
}

function handle_two_displays {
    echo "Re organise the spaces for two displays"
    yabai -m space --destroy 9
    yabai -m space --destroy 8
    yabai -m space --destroy 7
    yabai -m space --destroy 6

    echo "Create new spaces in second displays"
    # The only space in the monitor 2 will be uplifted to 6
    # space 7
    yabai -m space --create 2
    # space 8
    yabai -m space --create 2
    # space 9
    yabai -m space --create 2
    # space 0
    yabai -m space --create 2

    yabai --restart-service
}

if [ $size -eq 1 ]; then
    handle_one_display
elif [ $size -eq 2 ]; then
    handle_two_displays
else
    echo "More than 2 monitors. TBD future"
fi
