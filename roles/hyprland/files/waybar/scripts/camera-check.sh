#!/bin/bash

# Check if any camera is in use and output waybar JSON

# Find all video devices and check which are in use
output=""
while IFS= read -r line; do
    if [ -n "$line" ]; then
        output="${output}${line}\n"
    fi
done < <(for dev in /dev/video*; do
    if [ -e "$dev" ]; then
        # Check if device is in use using fuser
        pids=$(fuser "$dev" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$pids" ]; then
            # Get process info for each PID
            for pid in $pids; do
                if [ -n "$pid" ]; then
                    cmdline=$(cat /proc/$pid/comm 2>/dev/null || echo "unknown")
                    echo "PID: $pid - $cmdline"
                fi
            done
        fi
    fi
done | sort -u)

# Check if we found any processes using cameras
if [ -n "$output" ]; then
    # Camera is in use - show red circle with tooltip
    tooltip=$(echo -e "$output" | sed '/^$/d')
    echo "{\"text\":\"🔴\",\"tooltip\":\"$tooltip\",\"class\":\"camera-active\"}"
else
    # No camera in use - show nothing
    echo "{\"text\":\"\",\"tooltip\":\"No camera in use\",\"class\":\"camera-inactive\"}"
fi
