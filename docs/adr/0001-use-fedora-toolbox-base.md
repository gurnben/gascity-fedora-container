# 0001 — Use Fedora Toolbox as Base Image

## Status

Accepted

## Context

The container needs a base image that provides a rich interactive development
environment with broad package availability. Options considered:

- **Fedora minimal** — small footprint but missing interactive tooling
- **Ubuntu** — popular but DNF/RPM ecosystem preferred for Charm and Anthropic repos
- **Fedora toolbox** — purpose-built for interactive development with full Fedora userspace

## Decision

Use `registry.fedoraproject.org/fedora-toolbox:latest` as the base image.

## Consequences

- Native RPM repositories for crush (Charm) and claude-code (Anthropic) work without compatibility layers
- Larger image size compared to minimal bases, but acceptable for a development container
- Automatic access to latest Fedora packages including Go 1.25+
- Multi-stage build keeps the builder stage separate from the final image
