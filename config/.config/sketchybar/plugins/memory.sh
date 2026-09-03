#!/bin/bash

MEMORY_PERCENT=$(vm_stat | awk -v total_memory="$(sysctl -n hw.memsize)" '
  /page size of/ { page_size = $8 }
  /Anonymous pages:/ { anonymous = $3 }
  /Pages purgeable:/ { purgeable = $3 }
  /Pages wired down:/ { wired = $4 }
  /Pages occupied by compressor:/ { compressed = $5 }
  END {
    gsub("\\.", "", anonymous)
    gsub("\\.", "", purgeable)
    gsub("\\.", "", wired)
    gsub("\\.", "", compressed)
    used_pages = anonymous - purgeable + wired + compressed
    printf "%.0f", (used_pages * page_size / total_memory) * 100
  }
')

sketchybar --set "$NAME" label="$MEMORY_PERCENT%"
