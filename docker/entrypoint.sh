#!/bin/bash
set -euo pipefail

mkdir -p /run/proxmox-backup /etc/proxmox-backup /var/lib/proxmox-backup /var/log/proxmox-backup /backups

# Fix top-level ownership (non-recursive). PBS hard-checks /etc/proxmox-backup
# ownership at startup and refuses to run if it's not backup:backup (34:34).
# After a backup restore, mounted volumes often come back as 1000:1000.
chown backup:backup /etc/proxmox-backup /var/lib/proxmox-backup /var/log/proxmox-backup /backups
chmod 0700 /etc/proxmox-backup /var/lib/proxmox-backup /var/log/proxmox-backup
chown backup:backup /run/proxmox-backup
chmod 0755 /run/proxmox-backup

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
