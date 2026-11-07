#!/usr/bin/env bash
# Install an hourly cron job for backup.sh (idempotent). Override with SCHEDULE="*/30 * * * *".
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEDULE="${SCHEDULE:-0 * * * *}"
LINE="$SCHEDULE cd $DIR && ./backup.sh >> $DIR/backup.log 2>&1 # vault-snapshot"
( crontab -l 2>/dev/null | grep -v '# vault-snapshot' || true; echo "$LINE" ) | crontab -
echo "Installed: $LINE"
