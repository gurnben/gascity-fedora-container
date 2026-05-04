# Gastown Fedora Container

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

## Quick Start

### Pull the pre-built image

```bash
podman pull ghcr.io/gurnben/gastown-fedora-container:latest
```

### Run interactively

```bash
podman run --rm -it ghcr.io/gurnben/gastown-fedora-container:latest
```

### Use with Compose

```bash
podman-compose up -d
podman-compose exec gastown bash
```

### Build locally

```bash
podman build -t gastown-fedora -f Containerfile .
```

## Configuration

Gascity is pre-configured with a skeleton `city.toml` at
`/etc/skel/.config/gascity/city.toml` that uses the `bd` beads provider.
Override this by mounting your own config or setting `GC_BEADS=file` for a
simpler file-based store.

## CI/CD

- **Build & push** — on every push to `main` and weekly on Mondays
  (`.github/workflows/build-push.yaml`)
- **PR check** — validates the container builds on pull requests
  (`.github/workflows/pr-check.yaml`)
- **Dependabot** — checks base image, GitHub Actions, and npm dependencies
  weekly (`.github/dependabot.yml`)

## License

See [LICENSE](LICENSE).
