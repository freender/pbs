# PBS Docker (zavala)

Docker-based PBS image + compose deployment for cinci.

> [!WARNING]
> Unsupported and unofficial. This is a personal homelab project and is not affiliated with or supported by Proxmox.

## Runtime Paths

- `/mnt/cache/appdata/pbs/etc` -> `/etc/proxmox-backup`
- `/mnt/cache/appdata/pbs/lib` -> `/var/lib/proxmox-backup`
- `/mnt/cache/appdata/pbs/logs` -> `/var/log/proxmox-backup`
- `/mnt/cache/pbs-datastore` -> `/backups`

## Compose Usage

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs -f --tail=100
```

`compose.yml` tracks `ghcr.io/freender/pbs:latest`.

## Image Update Mechanism

Two GitHub Actions workflows handle updates:

1. `.github/workflows/check-updates.yml`
   - Runs daily.
   - Checks Proxmox `pbs-no-subscription` repo for latest `proxmox-backup-server` version.
   - If newer than `VERSION`, opens a PR bumping `VERSION`.

2. `.github/workflows/build-image.yml`
   - Runs on push to `main`.
   - Builds `docker/Dockerfile` with `PBS_VERSION` from `VERSION`.
   - Pushes image to `ghcr.io/freender/pbs` with tags:
     - `latest`
     - `<VERSION>`
   - Creates git tags:
     - `v<VERSION>` (immutable release tag)
     - `latest` (moving tag to newest release commit)

This keeps image updates explicit via PR, then automatic build/publish after merge.

## One-time User/ACL Setup

If you need to re-apply users after first cutover:

```bash
docker exec zavala bash -lc "proxmox-backup-manager user create xur-sync@pbs --password '<XUR_SYNC_PASSWORD>' --comment 'xur push sync only'"
docker exec zavala bash -lc "proxmox-backup-manager acl update /datastore/backup-cinci DatastoreBackup --auth-id xur-sync@pbs"

docker exec zavala bash -lc "proxmox-backup-manager user create xur-pull@pbs --password '<XUR_PULL_PASSWORD>' --comment 'xur DR restore read-only'"
docker exec zavala bash -lc "proxmox-backup-manager acl update /datastore/backup-cinci DatastoreReader --auth-id xur-pull@pbs"
```
