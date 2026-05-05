# Gastown Fedora Container

[![Build and Push](https://github.com/gurnben/gastown-fedora-container/actions/workflows/build-push.yaml/badge.svg)](https://github.com/gurnben/gastown-fedora-container/actions/workflows/build-push.yaml)

A Fedora toolbox-based development container pre-loaded with
[gascity](https://github.com/gastownhall/gascity) and popular agentic coding
runtimes.

## What's Included

| Tool | Version | Source |
|------|---------|--------|
| **gascity** (`gc`) | latest | Built from source |
| **crush** | RPM (Charm repo) | `repo.charm.sh/yum` |
| **claude-code** | RPM (Anthropic repo) | `downloads.claude.ai` |
| **opencode** | RPM (GitHub release) | `opencode-ai/opencode` |
| **gemini-cli** | npm | `@google/gemini-cli` |
| **dolt** | Install script | `dolthub/dolt` |
| **beads** (`bd`) | Install script | `gastownhall/beads` |

System dependencies (tmux, git, jq, lsof, flock, Go, Node.js) are installed
from Fedora's native repositories.

### ADR Pipeline Pack

The container ships a gascity pack at `/opt/adr-pipeline/` that implements
an ADR-driven development pipeline:

1. **Architecture phase** — architect writes an ADR, reviewer iterates (max 3 rounds), human approves
2. **Development phase** — planner breaks work into parallel tasks, dog pool implements, QE and senior review run in parallel, fix cycles loop, planner verifies against ADR

| Agent | Role | Type |
|-------|------|------|
| `architect` | Writes ADRs | Named session |
| `reviewer` | Reviews ADRs | Named session |
| `planner` | Breaks ADRs into tasks, dispatches, verifies | Named session |
| `dog` | Implements features | Pool (up to 6) |
| `qe` | Validates tests and coverage | Named session |
| `senior` | Code review | Named session |

## Installation

Pull the pre-built image:

```bash
podman pull ghcr.io/gurnben/gastown-fedora-container:latest
```

Or build locally:

```bash
make build
```

## Usage

### Basic

Run an interactive session with your projects and API keys:

```bash
podman run --rm -it --userns=keep-id:uid=1000,gid=1000 \
  -v ~/Projects:/workspace:Z \
  -v ~/.config:/home/gascity/.config:Z \
  -e ANTHROPIC_API_KEY \
  -e OPENAI_API_KEY \
  -e GEMINI_API_KEY \
  ghcr.io/gurnben/gastown-fedora-container:latest
```

### Google Cloud / Vertex AI

Run with Vertex AI authentication and a GCP service account key:

```bash
podman run --rm -it --userns=keep-id:uid=1000,gid=1000 \
  -v ~/Projects:/workspace:Z \
  -v ~/.config:/home/gascity/.config:Z \
  -v /path/to/gcp-service-account.json:/home/gascity/.config/gcloud/application_default_credentials.json:ro,Z \
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
  ghcr.io/gurnben/gastown-fedora-container:latest
```

> **Tip:** Export environment variables in your shell before running —
> bare `-e VAR` passes the host value through automatically.

> **Note:** Gascity's `gc init` readiness check only recognizes first-party
> `claude.ai` OAuth login. When using Vertex AI, the check will report
> "Claude Code: needs authentication" even though Claude is fully functional.
> Use the `--skip-provider-readiness` flag to bypass it:
>
> ```bash
> gc init --skip-provider-readiness ~/my-workspace
> ```

### Running in the Background

Start the container detached and exec into it as needed. Use `--pids-limit=-1`
to remove the default process limit — gascity spawns many subprocesses via
tmux, dolt, and agent runtimes that can exceed Podman's default of 2048:

```bash
# Start detached
podman run -d --name gascity --pids-limit=-1 --userns=keep-id:uid=1000,gid=1000 \
  -v ~/Projects:/workspace:Z \
  -v ~/.config:/home/gascity/.config:Z \
  ghcr.io/gurnben/gastown-fedora-container:latest \
  sleep infinity

# Attach an interactive shell
podman exec -it gascity bash

# Stop / restart / remove
podman stop gascity
podman start gascity
podman stop gascity && podman rm gascity
```

Environment variables passed via `-e` at `podman run` time are only visible
to the initial process. To make them available in every `exec` session, write
a profile script once after creating the container:

```bash
podman exec gascity sudo bash -c 'cat > /etc/profile.d/vertex.sh << "EOF"
export GOOGLE_APPLICATION_CREDENTIALS=/home/gascity/.config/gcloud/application_default_credentials.json
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID='"$ANTHROPIC_VERTEX_PROJECT_ID"'
export VERTEXAI_PROJECT="$ANTHROPIC_VERTEX_PROJECT_ID"
export VERTEXAI_LOCATION=global
export GOOGLE_CLOUD_PROJECT="$ANTHROPIC_VERTEX_PROJECT_ID"
export VERTEX_LOCATION=global
export GOOGLE_CLOUD_LOCATION=global
export GEMINI_API_KEY='"$GEMINI_API_KEY"'
EOF'
```

Then use a login shell to pick up the variables automatically:

```bash
podman exec -it gascity bash -l
```

- Start with Compose (mounts a persistent workspace volume):

  ```bash
  podman-compose up -d
  podman-compose exec gastown bash
  ```

- Initialize a gascity workspace inside the container:

  ```bash
  gc init --skip-provider-readiness /workspace
  cd /workspace
  ```

> **Note:** Containers do not run a user-level systemd instance, so
> `gc start` will fail to install its supervisor as a systemd service.
> Use foreground mode instead:
>
> ```bash
> # Run the supervisor in a background tmux session
> tmux new-session -d -s gc 'gc start --foreground'
>
> # Check on it anytime
> tmux attach -t gc
> ```

### Setting Up the ADR Pipeline Pack

After initializing a workspace, import the pre-installed ADR pipeline pack:

```bash
cd /workspace

# Add the pack import to your pack.toml
cat >> pack.toml << 'EOF'

[imports.pipeline]
source = "/opt/adr-pipeline"
export = true
EOF

# Install the import
gc import install
```

Then restart the supervisor to pick up the new agents:

```bash
tmux kill-session -t gc 2>/dev/null
gc unregister /workspace 2>/dev/null
tmux new-session -d -s gc 'gc start --foreground'
```

Verify the agents are running:

```bash
gc session list    # should show architect, reviewer, planner, qe, senior
gc doctor          # should pass all checks
```

### Using the Pipeline

**Start the architecture phase** (design → review → your approval):

```bash
gc formula cook mol-architecture --var feature="My Feature"
gc sling architect <bead-id>
```

The architect writes an ADR and iterates with the reviewer (up to 3 rounds).
When they converge, you'll receive a mail notification. Review the ADR and
approve the human gate to proceed.

**Start the development phase** (after approving the ADR):

```bash
gc formula cook mol-dev-pipeline \
  --var feature="My Feature" \
  --var adr="docs/adr/00XX-my-feature.md"
gc sling planner <bead-id>
```

The planner reads the ADR, breaks work into parallel tasks with file ownership
boundaries, dispatches to the dog pool (up to 6 agents), then QE and senior
review run in parallel. Fix cycles loop until quality gates pass, and the
planner runs a final check against the ADR.

- Launch an agentic runtime:

  ```bash
  crush                # Crush TUI
  claude               # Claude Code
  opencode             # OpenCode TUI
  gemini               # Gemini CLI
  ```

## Configuration

- Gascity ships with a skeleton `city.toml` at `/etc/skel/.config/gascity/city.toml` using the `bd` beads provider
- Override by mounting your own config or setting `GC_BEADS=file` for a simpler file-based store
- Each agentic runtime reads its own configuration from standard locations (`~/.config/crush/`, etc.)
- The container runs as the non-root `gascity` user (UID 1000) because Claude Code refuses to run as root
- Use `--userns=keep-id:uid=1000,gid=1000` so host file mounts are accessible to the container user
- Dolt and git identities are pre-configured with defaults; override with `dolt config` / `git config` as needed
- For Vertex AI, set the environment variables shown above and mount your GCP service account key JSON

## Development

Build and test locally:

```bash
make build          # Build the container image
make test           # Verify installed tools
make lint           # Lint the Containerfile
```

### CI/CD

- **Build & push** — on every push to `main` and weekly on Mondays (`.github/workflows/build-push.yaml`)
- **PR check** — validates the container builds on pull requests (`.github/workflows/pr-check.yaml`)
- **Dependabot** — checks base image, GitHub Actions, and npm dependencies weekly (`.github/dependabot.yml`)

## License

See [LICENSE](LICENSE).
