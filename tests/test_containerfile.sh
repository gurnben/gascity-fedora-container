#!/usr/bin/env bash
set -euo pipefail

if [ ! -f Containerfile ]; then
    echo "FAIL: Containerfile not found"
    exit 1
fi

stage_count=$(grep -ci '^FROM' Containerfile)
if [ "$stage_count" -ge 2 ]; then
    echo "PASS: Multi-stage build detected ($stage_count stages)"
else
    echo "FAIL: Expected multi-stage build, found $stage_count FROM"
    exit 1
fi

echo "PASS: Containerfile structure is valid"
