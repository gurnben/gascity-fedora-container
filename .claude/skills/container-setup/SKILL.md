---
name: container-setup
description: Use when the user wants to start, stop, configure, or debug the gastown-fedora-container with podman — including Vertex AI setup, gascity initialization, and session troubleshooting.
---

# Gastown Fedora Container Setup

This skill automates standing up and configuring the gastown-fedora-container
for agentic development with gascity.

## Prerequisites

The following environment variables must be set on the **host** before running:

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_VERTEX_PROJECT_ID` | GCP project ID for Vertex AI |
| `GCP_VERTEX_JSON_PATH` | Absolute path to GCP service account JSON key |
| `GEMINI_API_KEY` | API key for Gemini CLI |

For basic (non-Vertex) usage, only `ANTHROPIC_API_KEY` is required.

## Step 1 — Remove any existing container

```bash
podman stop gascity 2>/dev/null; podman rm gascity 2>/dev/null
```

## Step 2 — Start the container

### Basic (direct API keys)

```bash
podman run -d --name gascity --pids-limit=-1 \
  --userns=keep-id:uid=1000,gid=1000 \
  -v ~/Projects:/workspace:Z \
  -v ~/.config:/home/gascity/.config:Z \
  -e ANTHROPIC_API_KEY \
  -e OPENAI_API_KEY \
  -e GEMINI_API_KEY \
  ghcr.io/gurnben/gastown-fedora-container:latest \
  sleep infinity
```

### Google Cloud / Vertex AI

```bash
podman run -d --name gascity --pids-limit=-1 \
  --userns=keep-id:uid=1000,gid=1000 \
  -v ~/Projects:/workspace:Z \
  -v ~/.config:/home/gascity/.config:Z \
  -v $GCP_VERTEX_JSON_PATH:/home/gascity/.config/gcloud/application_default_credentials.json:ro,Z \
  -e GOOGLE_APPLICATION_CREDENTIALS=/home/gascity/.config/gcloud/application_default_credentials.json \
  -e CLAUDE_CODE_USE_VERTEX=1 \
  -e CLOUD_ML_REGION=global \
  -e ANTHROPIC_VERTEX_PROJECT_ID \
  -e VERTEXAI_PROJECT=$ANTHROPIC_VERTEX_PROJECT_ID \
  -e VERTEXAI_LOCATION=global \
  -e GOOGLE_CLOUD_PROJECT=$ANTHROPIC_VERTEX_PROJECT_ID \
  -e VERTEX_LOCATION=global \
  -e GOOGLE_CLOUD_LOCATION=global \
  -e GEMINI_API_KEY \
  ghcr.io/gurnben/gastown-fedora-container:latest \
  sleep infinity
```

### Key flags explained

- **`--pids-limit=-1`** — removes the default 2048 process limit; gascity
  spawns many subprocesses via tmux, dolt, and agent runtimes
- **`--userns=keep-id:uid=1000,gid=1000`** — maps the host user to the
  container's `gascity` user (UID 1000) so mounted files are accessible
- **`sleep infinity`** — keeps the container alive; the entrypoint for
  gascity is started manually inside

## Step 3 — Persist environment variables for all exec sessions

Environment variables passed via `-e` at `podman run` time are only visible to
the initial process (`sleep infinity`). Write them to `/etc/profile.d/` so
every `bash -l` session inherits them:

### Vertex AI

```bash
podman exec gascity sudo bash -c 'cat > /etc/profile.d/vertex.sh << "EOF"
export GOOGLE_APPLICATION_CREDENTIALS=/home/gascity/.config/gcloud/application_default_credentials.json
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID='"$ANTHROPIC_VERTEX_PROJECT_ID"'
export VERTEXAI_PROJECT=$ANTHROPIC_VERTEX_PROJECT_ID
export VERTEXAI_LOCATION=global
export GOOGLE_CLOUD_PROJECT=$ANTHROPIC_VERTEX_PROJECT_ID
export VERTEX_LOCATION=global
export GOOGLE_CLOUD_LOCATION=global
export GEMINI_API_KEY='"$GEMINI_API_KEY"'
EOF'
```

## Step 4 — Enter the container

```bash
podman exec -it gascity bash -l
```

The `-l` flag starts a login shell that sources `/etc/profile.d/`.

## Step 5 — Configure identities and verify tools

Ensure dolt and git have identities configured (required for the beads store):

```bash
podman exec gascity bash -lc 'dolt config --global --add user.name "gascity" && dolt config --global --add user.email "gascity@container.local" && git config --global user.name "gascity" && git config --global user.email "gascity@container.local"'
```

Verify tools:

```bash
claude --version
gc version
gh --version
```

Test Vertex AI authentication:

```bash
claude -p "respond with hello" --output-format text
```

## Step 6 — Initialize a gascity workspace

```bash
cd /workspace
gc init --skip-provider-readiness .
```

> The `--skip-provider-readiness` flag is required when using Vertex AI because
> gascity's readiness check only recognizes first-party `claude.ai` OAuth login.

## Step 7 — Start the gascity supervisor

Containers do not have a user-level systemd instance. Start the supervisor in
foreground mode inside a tmux session:

```bash
tmux new-session -d -s gc 'gc start --foreground'
```

Check on it anytime:

```bash
tmux attach -t gc
```

## Step 8 — Verify sessions

```bash
gc session list
gc doctor
```

All sessions should show `active` state. Doctor should report all checks passing.

## Troubleshooting

### Sessions flapping (creating → failed-create → creating)

A stale bead with `pending_create_claim` can cause infinite flapping. Fix:

```bash
gc session list                     # find the stuck session ID
gc bd close <id>                    # close the stale bead
bd delete <id> --force              # remove it permanently
```

The supervisor will create a fresh session automatically.

### "resource temporarily unavailable" from bd/dolt

The container has hit its PID limit. Recreate with `--pids-limit=-1`.

### "Permission denied" on mounted files

The `--userns=keep-id:uid=1000,gid=1000` flag was missing. Recreate the
container with it.

### "systemctl --user daemon-reload: exit status 1"

Expected in containers — systemd is not available. Use
`gc start --foreground` instead of `gc start`.

### "needs authentication" during gc init

Use `gc init --skip-provider-readiness` when using Vertex AI.

### Mayor/boot sessions stuck in failed-create from prior runs

Delete the stale beads and let the supervisor recreate them:

```bash
gc bd close <stuck-id>
bd delete <stuck-id> --force
```

### Container lifecycle

```bash
podman stop gascity          # stop
podman start gascity         # restart (keeps state)
podman stop gascity && podman rm gascity  # destroy
```
