# CLAUDE.md

## Project Overview

This repository contains a Containerfile that builds a Fedora toolbox-based
development container. The container includes the gascity multi-agent
orchestration SDK and several agentic coding runtimes.

## Repository Structure

```
.
├── Containerfile                    # Multi-stage container build definition
├── compose.yaml                     # Compose configuration for local development
├── .dockerignore                    # Files excluded from container build context
├── .github/
│   ├── dependabot.yml               # Weekly dependency update configuration
│   └── workflows/
│       ├── build-push.yaml          # Build and push to GHCR on main/schedule
│       └── pr-check.yaml            # Validate build on pull requests
├── README.md                        # User-facing documentation
└── CLAUDE.md                        # This file — AI agent context
```

## Build Commands

```bash
# Build the container locally
podman build -t gastown-fedora -f Containerfile .

# Run the container
podman run --rm -it gastown-fedora

# Use compose
podman-compose up -d
```

## Key Design Decisions

- **Multi-stage build**: Stage 1 compiles gascity from source with Go;
  stage 2 is the runtime image that copies only the binary.
- **Native RPMs preferred**: crush (Charm repo), claude-code (Anthropic repo),
  and opencode (GitHub release RPM) are installed as RPMs. gemini-cli uses npm
  since no RPM is available.
- **fedora-toolbox:latest base**: Provides a rich interactive environment
  suitable for development workflows.
- **Dependabot**: Monitors base image, GitHub Actions, and npm for weekly
  updates that trigger automatic rebuilds.

## Common Tasks

| Task | Command |
|------|---------|
| Build container | `podman build -t gastown-fedora -f Containerfile .` |
| Lint Containerfile | `hadolint Containerfile` |
| Test image | `podman run --rm gastown-fedora gc version` |
