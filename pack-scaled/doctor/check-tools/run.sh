#!/usr/bin/env bash
set -euo pipefail

missing=0
for tool in gc claude gh tmux git jq dolt bd; do
    if ! command -v "$tool" &>/dev/null; then
        echo "$tool not found in PATH"
        missing=1
    fi
done

if [ "$missing" -ne 0 ]; then
    exit 1
fi

echo "all required tools available"
