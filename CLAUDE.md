# CLAUDE.md

## Project Overview

This repository contains a Containerfile that builds a Fedora toolbox-based
development container. The container includes the gascity multi-agent
orchestration SDK, agentic coding runtimes, and an ADR-driven development
pipeline pack.

## Repository Structure

```
.
├── Containerfile                    # Multi-stage container build definition
├── compose.yaml                     # Compose configuration for local development
├── .dockerignore                    # Files excluded from container build context
├── pack/                            # ADR pipeline pack (copied to /opt/adr-pipeline/)
│   ├── pack.toml                    # Pack definition with named sessions
│   ├── agents/                      # Agent configs and prompts
│   ├── formulas/                    # mol-architecture and mol-dev-pipeline
│   ├── assets/scripts/              # Smoke test hook
│   └── doctor/                      # Pack health checks
├── .claude/skills/container-setup/  # Skill for standing up and configuring the container
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
podman build -t gascity-fedora -f Containerfile .   # build locally
make build                                          # same via Makefile
make test                                           # verify tools
make lint                                           # lint Containerfile
```

## Key Design Decisions

- **Multi-stage build**: Stage 1 compiles gascity from source with Go;
  stage 2 is the runtime image that copies only the binary.
- **Native RPMs preferred**: crush (Charm repo), claude-code (Anthropic repo),
  and opencode (GitHub release RPM) are installed as RPMs. gemini-cli uses npm
  since no RPM is available.
- **Non-root user**: Container runs as `gascity` (UID 1000) because Claude Code
  refuses to run as root. Use `--userns=keep-id:uid=1000,gid=1000` for mounts.
- **YOLO mode**: Claude Code runs with `--dangerously-skip-permissions`. Use
  dedicated credentials with limited scope.
- **ADR pipeline pack**: Ships at `/opt/adr-pipeline/` with agents (mayor,
  architect, reviewer, planner, dog pool, qe, senior) and two formulas
  (mol-architecture, mol-dev-pipeline).
- **Opus 4.6 1M default**: Configured via a `claude-opus` provider preset in
  `city.toml`.

## Skills

- **container-setup** (`.claude/skills/container-setup/SKILL.md`): Step-by-step
  guide for starting the container, configuring Vertex AI, importing the ADR
  pipeline pack, and troubleshooting common issues.
