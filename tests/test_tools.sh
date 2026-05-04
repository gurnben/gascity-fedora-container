#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-gastown-fedora:latest}"

tools=(
    "gc version"
    "dolt version"
    "bd version"
    "crush --version"
    "claude --version"
    "opencode version"
    "gemini --version"
)

failed=0
for cmd in "${tools[@]}"; do
    if podman run --rm "$IMAGE" $cmd >/dev/null 2>&1; then
        echo "PASS: $cmd"
    else
        echo "FAIL: $cmd"
        failed=1
    fi
done

exit $failed
