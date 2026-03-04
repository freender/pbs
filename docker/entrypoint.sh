#!/bin/bash
set -euo pipefail

mkdir -p /run/proxmox-backup /etc/proxmox-backup /var/lib/proxmox-backup /var/log/proxmox-backup /backups
chmod 0755 /run/proxmox-backup
chown backup:backup /run/proxmox-backup

if [[ -n "${TZ:-}" ]] && [[ -f "/usr/share/zoneinfo/${TZ}" ]]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  printf '%s\n' "${TZ}" > /etc/timezone
fi

if [[ ! -f /etc/proxmox-backup/.initialized ]]; then
  touch /etc/proxmox-backup/.initialized
fi

exec runsvdir -P /etc/service
