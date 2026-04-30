#!/bin/bash

# Temporary file paths
SCREENSHOT_PATH="/tmp/screenshot_ocr.png"
TEXT_PATH="/tmp/ocr_text.txt"

# Take screenshot with flameshot
flameshot gui --raw > "$SCREENSHOT_PATH"

# Run OCR on the screenshot
tesseract "$SCREENSHOT_PATH" "${TEXT_PATH%.*}"

# Copy the OCR text to clipboard
cat "$TEXT_PATH" | xclip -selection clipboard

# Optional: Notify user
notify-send "OCR Complete" "Text copied to clipboard"

# Optional: Clean up temp files
rm "$SCREENSHOT_PATH" "$TEXT_PATH"
