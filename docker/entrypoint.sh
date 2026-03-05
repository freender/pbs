#!/bin/bash
set -euo pipefail

mkdir -p /run/proxmox-backup /etc/proxmox-backup /var/lib/proxmox-backup /var/log/proxmox-backup /backups

# Fix permissions after backup restore (volumes come back as 1000:1000).
# Recursive on small config/state/log dirs — safe, they're never large.
# /backups is top-level only: datastore can be terabytes; PBS API (root) can
# traverse it regardless, and the proxy only needs the mount point itself.
chown -R backup:backup /etc/proxmox-backup /var/lib/proxmox-backup /var/log/proxmox-backup
chmod 0700 /etc/proxmox-backup /var/lib/proxmox-backup /var/log/proxmox-backup
chown backup:backup /backups
chown backup:backup /run/proxmox-backup
chmod 0755 /run/proxmox-backup

# acme dir is managed by root (cert renewal runs as root); restore leaves it
# as 1000:1000 with 0755. Fix ownership and mode back to root:root 0700.
if [[ -d /etc/proxmox-backup/acme ]]; then
  chown -R root:root /etc/proxmox-backup/acme
  chmod -R 0700 /etc/proxmox-backup/acme
fi

# Remove stale lock files from unclean shutdown
rm -f /etc/proxmox-backup/.*.lck /etc/proxmox-backup/*.lock

if [[ -n "${TZ:-}" ]] && [[ -f "/usr/share/zoneinfo/${TZ}" ]]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  printf '%s\n' "${TZ}" > /etc/timezone
fi

if [[ ! -f /etc/proxmox-backup/.initialized ]]; then
  touch /etc/proxmox-backup/.initialized
fi

exec runsvdir -P /etc/service
