# Gastown Fedora Container

[![Build and Push](https://github.com/gurnben/gascity-fedora-container/actions/workflows/build-push.yaml/badge.svg)](https://github.com/gurnben/gascity-fedora-container/actions/workflows/build-push.yaml)

A Fedora toolbox-based development container with
[gascity](https://github.com/gastownhall/gascity) multi-agent orchestration
and an ADR-driven development pipeline.

## Security Warning

> **This container runs Claude Code with `--dangerously-skip-permissions`
> (YOLO mode).** Agents can execute arbitrary shell commands, read/write files,
> and push to git remotes without confirmation.
>
> - **Use a dedicated GitHub account** with limited repository access
> - **Use a scoped token** — grant only the repos the agents need
> - **Never pass your personal credentials** into the container
> - **Mount SSH keys read-only** (`:ro`) so agents cannot modify them
> - **Review agent output** before merging any PRs they create

## What's Included

| Tool | Source |
|------|--------|
| **gascity** (`gc`) | Built from source |
| **crush** | Charm RPM repo |
| **claude-code** | Anthropic RPM repo |
| **opencode** | GitHub release RPM |
| **gemini-cli** | npm |
| **dolt** / **beads** (`bd`) | Install scripts |
| **gh** / **git** / **tmux** / **jq** | Fedora RPMs |

### ADR Pipeline Pack

Ships at `/opt/adr-pipeline/` — an agent pipeline for ADR-driven development:

| Agent | Role |
|-------|------|
| `mayor` | Orchestrates the pipeline — your primary interface |
| `architect` | Writes ADRs |
| `reviewer` | Reviews ADRs (max 3 rounds) |
| `planner` | Breaks ADRs into parallel tasks, dispatches, verifies |
| `dog` | Implements features (pool, up to 6 agents) |
| `qe` | Validates tests and coverage |
| `senior` | Senior code review |

## Quick Start

### 1. Start the container

```bash
podman run -d --name gascity --pids-limit=-1 \
  --userns=keep-id:uid=1000,gid=1000 \
  -v ~/Projects:/workspace:Z \
  -v ~/.config:/home/gascity/.config:Z \
  -v ~/.ssh/agent-key:/home/gascity/.ssh/id_ed25519:ro,Z \
  -e GH_TOKEN \
  -e ANTHROPIC_API_KEY \
  ghcr.io/gurnben/gascity-fedora-container:latest \
  sleep infinity
```

For Vertex AI, replace `-e ANTHROPIC_API_KEY` with:

```bash
  -v /path/to/gcp-key.json:/home/gascity/.config/gcloud/application_default_credentials.json:ro,Z \
  -e GOOGLE_APPLICATION_CREDENTIALS=/home/gascity/.config/gcloud/application_default_credentials.json \
  -e CLAUDE_CODE_USE_VERTEX=1 \
  -e CLOUD_ML_REGION=global \
  -e ANTHROPIC_VERTEX_PROJECT_ID \
  -e VERTEXAI_PROJECT="$ANTHROPIC_VERTEX_PROJECT_ID" \
  -e VERTEXAI_LOCATION=global \
  -e GOOGLE_CLOUD_PROJECT="$ANTHROPIC_VERTEX_PROJECT_ID" \
  -e VERTEX_LOCATION=global \
  -e GOOGLE_CLOUD_LOCATION=global \
  -e GEMINI_API_KEY \
```

Key flags:
- **`--pids-limit=-1`** — gascity needs more than Podman's default 2048 processes
- **`--userns=keep-id:uid=1000,gid=1000`** — maps host UID to container user for file access

### 2. Persist environment variables

Variables from `-e` only reach the initial process. Write them to `/etc/profile.d/`:

```bash
podman exec gascity sudo bash -c 'cat > /etc/profile.d/github.sh << "EOF"
export GH_TOKEN='"$GH_TOKEN"'
EOF'
podman exec gascity bash -lc 'gh auth setup-git'
```

For Vertex AI, also write the vertex env vars (see the
[container-setup skill](.claude/skills/container-setup/SKILL.md) for the full
command).

### 3. Configure identities

```bash
podman exec gascity bash -lc \
  'git config --global user.name "my-agent" && \
   git config --global user.email "my-agent@users.noreply.github.com" && \
   dolt config --global --add user.name "my-agent" && \
   dolt config --global --add user.email "my-agent@users.noreply.github.com"'
```

### 4. Initialize workspace and import the pipeline

```bash
podman exec gascity bash -lc 'cd /workspace && gc init --skip-provider-readiness .'
podman exec gascity bash -lc 'cd /workspace && cat >> pack.toml << "EOF"

[imports.pipeline]
source = "/opt/adr-pipeline"
export = true
EOF'
podman exec gascity bash -lc 'cd /workspace && gc import install'
```

> Use `--skip-provider-readiness` with Vertex AI — gascity only recognizes
> first-party `claude.ai` OAuth.

### 5. Start the supervisor

Containers lack systemd — use foreground mode in tmux:

```bash
podman exec gascity bash -lc \
  'cd /workspace && gc unregister /workspace 2>/dev/null; \
   tmux new-session -d -s gc "gc start --foreground"'
```

### 6. Verify and enter

```bash
# Wait ~2 minutes for all sessions to start, then:
podman exec gascity bash -lc 'cd /workspace && gc session list'
podman exec -it gascity bash -l
```

## Using the Pipeline

Attach to the mayor — your primary orchestration interface:

```bash
gc session attach pipeline.mayor
```

Tell the mayor what to build in plain language. It will:

1. Cook `mol-architecture` and sling to the architect
2. Monitor the architect ↔ reviewer cycle
3. Notify you when the ADR is ready (`gc mail inbox`)
4. After your approval, cook `mol-dev-pipeline` and sling to the planner
5. Monitor development, QE, senior review, and fix cycles
6. Notify you when the feature is complete

Detach anytime with `Ctrl-b d`.

### Manual dispatch (without the mayor)

```bash
# Architecture phase
gc formula cook mol-architecture --var feature="My Feature"
gc sling pipeline.architect <bead-id>

# Development phase (after ADR approval)
gc formula cook mol-dev-pipeline \
  --var feature="My Feature" \
  --var adr="docs/adr/00XX-my-feature.md"
gc sling pipeline.planner <bead-id>
```

### Adding repositories

```bash
cd /workspace
git clone git@github.com:your-org/repo-name.git
gc rig add /workspace/repo-name --name repo-name
```

## Configuration

### Model Selection

All agents default to Claude Opus 4.6 1M via `city.toml`:

```toml
[workspace]
provider = "claude-opus"

[providers.claude-opus]
base = "claude"
args_append = ["--model", "claude-opus-4-6"]
```

Override per agent in `agent.toml` or define additional presets.

### Container Lifecycle

```bash
podman stop gascity                     # stop (preserves state)
podman start gascity                    # restart
podman stop gascity && podman rm gascity  # destroy
```

After restart, re-run step 5 to start the supervisor.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Sessions flapping | `gc bd close <id> && bd delete <id> --force` |
| "resource temporarily unavailable" | Recreate with `--pids-limit=-1` |
| "Permission denied" on mounts | Add `--userns=keep-id:uid=1000,gid=1000` |
| "systemctl daemon-reload" error | Expected — use `gc start --foreground` |
| "needs authentication" on init | Use `--skip-provider-readiness` |

## Development

```bash
make build    # Build container image
make test     # Verify installed tools
make lint     # Lint the Containerfile
```

- **Build & push** — on push to `main` and weekly Mondays
- **PR check** — validates build on pull requests
- **Dependabot** — weekly updates for base image, Actions, and npm

## License

See [LICENSE](LICENSE).
