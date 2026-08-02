#!/bin/bash
# Suspend, but if we're inside 9am–9pm, defer until 9pm.
# on-resume in hypridle.conf kills this script if activity resumes during the sleep.
hour=$(date +%H)
if [ "$hour" -ge 9 ] && [ "$hour" -lt 21 ]; then
    sleep $(( $(date -d "21:00" +%s) - $(date +%s) ))
fi
systemctl suspend
