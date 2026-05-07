#!/usr/bin/env bash
# Dismiss Claude Code interactive onboarding prompts (theme selector +
# security notice) from all gascity tmux sessions. Run after gc start.
set -euo pipefail

SOCKET="${1:-workspace}"
MAX_ROUNDS=5
DELAY=5

for round in $(seq 1 $MAX_ROUNDS); do
    dismissed=0
    for s in $(tmux -L "$SOCKET" list-sessions -F '#{session_name}' 2>/dev/null); do
        content=$(tmux -L "$SOCKET" capture-pane -t "$s" -p 2>/dev/null || true)
        if echo "$content" | grep -q "Choose the text style"; then
            tmux -L "$SOCKET" send-keys -t "$s" "2" Enter
            dismissed=$((dismissed + 1))
        elif echo "$content" | grep -q "Press Enter to continue"; then
            tmux -L "$SOCKET" send-keys -t "$s" Enter
            dismissed=$((dismissed + 1))
        fi
    done
    if [ "$dismissed" -eq 0 ]; then
        break
    fi
    sleep "$DELAY"
done
