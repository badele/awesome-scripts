#!/usr/bin/env bash

set -euo pipefail

function show_usage() {
    echo "Usage: $0 <palette_name> "
    echo ""
    echo "Download Lospec palette"
    echo ""
    echo "Arguments:"
    echo "  palette_name   Name of the Lospec palette (e.g., 'gunsgax20')"
    exit 1
}

function download_palette() {
    local palette_name="$1"
    local palette_file="$2"
    local palette_url="https://lospec.com/palette-list/${palette_name}-32x.png"

    echo "Downloading palette from: $palette_url"

    if ! curl -sL "$palette_url" -o "$palette_file"; then
        echo "Error: Failed to download ${palette_url} palette"
        exit 1
    fi

    if [ ! -s "$palette_file" ]; then
        echo "Error: Downloaded palette file is empty"
        rm -f "$palette_file"
        exit 1
    fi
}

if [ -z "$1" ]; then
    show_usage
fi

PALETTE_NAME="$1"
PALETTE_FILE="palettes/$PALETTE_NAME.png"

download_palette "$PALETTE_NAME" "$PALETTE_FILE"
