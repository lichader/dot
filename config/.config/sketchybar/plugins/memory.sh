#!/bin/bash

MEMORY_PERCENT=$(vm_stat | awk -v total_memory="$(sysctl -n hw.memsize)" '
  /page size of/ { page_size = $8 }
  /Pages active:/ { active = $3 }
  /Pages wired down:/ { wired = $4 }
  END {
    gsub("\\.", "", active)
    gsub("\\.", "", wired)
    printf "%.0f", ((active + wired) * page_size / total_memory) * 100
  }
')

sketchybar --set "$NAME" label="$MEMORY_PERCENT%"
