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

- Run an interactive session inside the container:

  ```bash
  podman run --rm -it ghcr.io/gurnben/gastown-fedora-container:latest
  ```

- Start with Compose (mounts a persistent workspace volume):

  ```bash
  podman-compose up -d
  podman-compose exec gastown bash
  ```

- Initialize a gascity workspace inside the container:

  ```bash
  gc init ~/my-workspace
  cd ~/my-workspace
  gc start
  ```

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
