# AGENTS.md — PBS Docker (zavala)

## Project Overview

Unofficial containerized Proxmox Backup Server for homelab use.
Published to `ghcr.io/freender/pbs`. No application code — this is a
Docker infrastructure repo with a Dockerfile, entrypoint script, Compose
file, and two CI workflows that automate version tracking, building, and
publishing.

## Repository Layout

```
VERSION                        # Single line: current PBS version (e.g. 4.1.4-1)
compose.yml                    # Docker Compose for deployment (container: zavala)
docker/
  Dockerfile                   # Debian trixie + Proxmox pbs-no-subscription repo
  entrypoint.sh                # Runtime init (dirs, TZ, runit)
.github/workflows/
  check-updates.yml            # Daily cron: detect new PBS versions, commit bump
  build-image.yml              # On push to main: build image, push to GHCR, tag
README.md
```

## Build & Run Commands

### Build the Docker image locally

```bash
# With pinned version (matches CI behavior)
docker build -f docker/Dockerfile --build-arg PBS_VERSION=$(cat VERSION) -t pbs:local .

# Without version pin (latest from apt)
docker build -f docker/Dockerfile -t pbs:local .
```

### Run via Compose

```bash
docker compose pull          # pull latest from GHCR
docker compose up -d         # start container "zavala"
docker compose logs -f       # follow logs
docker compose down          # stop
```

### Run locally built image

```bash
# Override image in compose
docker compose up -d --build
```

## Testing

There are no automated tests. Validation is manual:

```bash
# 1. Build the image
docker build -f docker/Dockerfile --build-arg PBS_VERSION=$(cat VERSION) -t pbs:test .

# 2. Smoke-test: container starts and listens on 8007
docker run --rm -d --name pbs-test -p 8007:8007 pbs:test
sleep 5
curl -kso /dev/null -w '%{http_code}' https://localhost:8007  # expect 200 or 301
docker stop pbs-test
```

### Linting

```bash
# Dockerfile lint
docker run --rm -i hadolint/hadolint < docker/Dockerfile

# Shell script lint
shellcheck docker/entrypoint.sh

# YAML lint
yamllint compose.yml .github/workflows/*.yml
```

None of these are enforced in CI — run them locally before committing.

## CI / CD Pipeline

```
check-updates.yml (daily 08:15 UTC)
  -> detects new PBS version in Proxmox apt repo
  -> commits VERSION bump to main

build-image.yml (on push to main, or manual)
  -> reads VERSION
  -> builds docker/Dockerfile with PBS_VERSION=<version>
  -> pushes to ghcr.io/freender/pbs:<version> + :latest
  -> creates git tag v<version> (immutable) and moves `latest` tag
```

Pushing to `main` triggers a full build+publish. The daily cron creates
the push automatically when a new PBS version is detected.

## Code Style & Conventions

### General

- This is an infrastructure-only repo. Keep it minimal — no unnecessary
  abstractions or tooling.
- Prefer clarity over cleverness. Every file should be self-explanatory.
- Keep the total file count low. Do not add files unless strictly needed.

### Dockerfile (`docker/Dockerfile`)

- Base image: `debian:trixie`. Do not change base distro without good reason.
- Use `set -euo pipefail` semantics (RUN commands fail on error by default).
- Minimize layers: combine related `apt-get` commands with `&&` and clean
  up (`rm -rf /var/lib/apt/lists/*`) in the same layer.
- Pin package versions via the `PBS_VERSION` build arg when available.
- Use heredocs (`<<'EOF'`) for multi-line file creation inside RUN.
- Keep the subscription nag patch in place (the `no-nag-script` block).
- Process supervisor: `runit` (`runsvdir`). Each service gets a
  `/etc/service/<name>/run` script.

### Shell Scripts (`docker/entrypoint.sh`)

- Always start with `#!/bin/bash` and `set -euo pipefail`.
- Use `[[ ]]` for conditionals (bash-specific is fine here).
- Use `${VAR:-}` for optional env vars to avoid unbound variable errors.
- Use `printf '%s\n'` over `echo` for writing data to files.
- Use `exec` for the final process (PID 1 handoff to runit).
- Keep scripts short — delegate to runit service scripts for long-running
  processes.

### Compose (`compose.yml`)

- Container name: `zavala`. Do not rename without updating docs.
- Volumes mount to `/mnt/cache/appdata/pbs/*` (homelab convention).
- Use `tmpfs` for `/run` and `/tmp`.
- Memory limit: `2g`. Adjust only if PBS requires more.
- Deploy script runs `docker compose pull` before `up -d` to ensure fresh images.

### GitHub Actions Workflows

- All scripts use `set -euo pipefail` at the top.
- Use `$GITHUB_OUTPUT` for passing values between steps (not `set-output`).
- Git operations use the `github-actions[bot]` identity.
- Version tags: `v<VERSION>` (immutable). The `latest` tag is force-moved.
- Commit messages for automated bumps: `chore: bump PBS to <version>`.

### VERSION File

- Single line, no trailing whitespace, no leading `v`.
- Format: `<major>.<minor>.<patch>-<debian_revision>` (e.g. `4.1.4-1`).
- Updated only by the `check-updates.yml` workflow or manually.

### Commit Messages

- Follow conventional commits: `chore:`, `fix:`, `feat:`, `docs:`.
- Automated version bumps use `chore: bump PBS to <version>`.
- Keep messages concise — one line unless more context is truly needed.

### Error Handling

- All shell: `set -euo pipefail`. No exceptions.
- CI steps: fail explicitly with `exit 1` and a message to stderr on error.
- Dockerfile: each RUN should either succeed fully or fail the build.

## Key Details for Agents

- **No tests to run.** Validation is building the image + smoke test.
- **No package manager.** No npm, pip, cargo, etc. Just apt inside Docker.
- **No linting in CI.** Run hadolint/shellcheck locally if modifying
  Dockerfile or shell scripts.
- **VERSION is the source of truth** for the PBS version to build. CI reads
  it; never hardcode versions elsewhere.
- **Port 8007** is the only exposed port (Proxmox Backup Server web UI).
- The Dockerfile build context is the repo root (`.`), not `docker/`.
