# PBS Docker (zavala)

Unofficial containerized [Proxmox Backup Server](https://www.proxmox.com/en/proxmox-backup-server/overview) for homelab use.

> [!WARNING]
> Not affiliated with or supported by Proxmox.

## Quick Start

```bash
docker compose pull
docker compose up -d
```

Web UI: `https://<host>:8007` (default login: `root@pam`)

## Volumes

| Host | Container |
|---|---|
| `/mnt/cache/appdata/pbs/etc` | `/etc/proxmox-backup` |
| `/mnt/cache/appdata/pbs/lib` | `/var/lib/proxmox-backup` |
| `/mnt/cache/appdata/pbs/logs` | `/var/log/proxmox-backup` |
| `/mnt/cache/pbs-datastore` | `/backups` |

## Image Updates

Fully automated via two GitHub Actions workflows:

1. **`check-updates.yml`** — runs daily, checks the Proxmox `pbs-no-subscription` apt repo for new `proxmox-backup-server` versions, commits the bump directly to `main`.
2. **`build-image.yml`** — triggered on push to `main`, builds the image and pushes to `ghcr.io/freender/pbs` with both a pinned version tag and `latest`.

```
detect new version -> commit to main -> build -> push image + git tags
```

### Tags

| Type | Docker | Git |
|---|---|---|
| Pinned (immutable) | `ghcr.io/freender/pbs:<VERSION>` | `v<VERSION>` |
| Latest (moving) | `ghcr.io/freender/pbs:latest` | `latest` |

`compose.yml` tracks `:latest` with `pull_policy: always`.
