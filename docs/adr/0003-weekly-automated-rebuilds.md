# 0003 — Weekly Automated Rebuilds via Dependabot and Schedule

## Status

Accepted

## Context

The container image depends on upstream base images, RPM packages, npm packages,
and GitHub Actions. These change frequently and may include security fixes.

## Decision

Use three mechanisms for automated updates:

1. **Dependabot** — weekly checks for Docker base image, GitHub Actions, and npm dependency updates
2. **Scheduled CI** — weekly cron job (`0 6 * * 1`) rebuilds and pushes the image every Monday
3. **Push-triggered CI** — every merge to `main` triggers a fresh build

## Consequences

- Container image stays current with upstream security patches within one week
- Dependabot PRs surface version changes for review before merge
- Scheduled rebuilds catch updates that Dependabot does not monitor (e.g., dolt install script changes)
- Weekly cadence balances freshness against CI resource consumption
