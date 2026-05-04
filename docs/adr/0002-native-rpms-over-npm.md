# 0002 — Native RPMs Over npm/Binary Installs

## Status

Accepted

## Context

Agentic runtimes can be installed via multiple methods: native RPMs, npm global
packages, Go install, or downloading release binaries. A consistent strategy is
needed for maintainability and security updates.

## Decision

Prefer native RPM packages from vendor-managed repositories where available:

- **crush** — Charm YUM repository (`repo.charm.sh/yum`)
- **claude-code** — Anthropic DNF repository (`downloads.claude.ai`)
- **opencode** — RPM from GitHub releases (no vendor repo available)

Fall back to npm only when no RPM exists (gemini-cli).

## Consequences

- RPM-installed tools benefit from `dnf update` and Dependabot ecosystem monitoring
- Consistent package management via DNF across most tools
- opencode pinned to a specific release version requires manual bumps
- gemini-cli managed by npm requires Node.js in the image
