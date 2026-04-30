#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: clipboard-to-file <filename>"
    exit 1
fi

# Add .png extension if not present
filename="$1"
[[ "$filename" != *.png ]] && filename="${filename}.png"

# Save clipboard image to file
wl-paste > "$filename"

if [ $? -eq 0 ]; then
    echo "Saved clipboard image to: $filename"
else
    echo "Error: No image in clipboard or failed to save"
    exit 1
fi
