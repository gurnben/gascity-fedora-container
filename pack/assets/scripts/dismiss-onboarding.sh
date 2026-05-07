#!/usr/bin/env bash
# Continuously dismiss Claude Code interactive onboarding prompts (theme
# selector + security notice) from gascity tmux sessions. Runs as a daemon
# to catch dynamically scaled pool sessions as they spawn.
set -euo pipefail

SOCKET="${1:-workspace}"
POLL_INTERVAL="${2:-5}"

while true; do
    for s in $(tmux -L "$SOCKET" list-sessions -F '#{session_name}' 2>/dev/null); do
        content=$(tmux -L "$SOCKET" capture-pane -t "$s" -p 2>/dev/null || true)
        if echo "$content" | grep -q "Choose the text style"; then
            tmux -L "$SOCKET" send-keys -t "$s" "2" Enter
        elif echo "$content" | grep -q "Press Enter to continue"; then
            tmux -L "$SOCKET" send-keys -t "$s" Enter
        fi
    done
    sleep "$POLL_INTERVAL"
done
