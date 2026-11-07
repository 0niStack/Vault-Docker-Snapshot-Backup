#!/usr/bin/env bash
# Restore a Raft snapshot.
#   ./restore.sh                   -> latest snapshot (asks for confirmation)
#   ./restore.sh path/to/x.snapshot
#   ./restore.sh -y [file]         -> no prompt
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/../lib.sh"
need docker jq

YES=0
if [ "${1:-}" = "-y" ]; then YES=1; shift; fi
FILE="${1:-}"
if [ -z "$FILE" ]; then
  FILE="$(ls -1t "$DIR"/../3-backup/snapshots/vault-raft_*.snapshot 2>/dev/null | head -1 || true)"
fi
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "ERROR: no snapshot found (run 3-backup/backup.sh first)" >&2; exit 1; }

echo "Snapshot to restore: $FILE"
if [ "$YES" -ne 1 ]; then
  read -r -p "This OVERWRITES all current HashiCorp Vault data. Continue? [y/N] " a
  [[ "$a" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

unseal_if_needed
echo "==> Copying snapshot into container"
docker cp "$FILE" "$CONTAINER":/tmp/restore.snapshot

echo "==> Restoring"
vault_cmd operator raft snapshot restore -force /tmp/restore.snapshot
docker exec "$CONTAINER" rm -f /tmp/restore.snapshot

sleep 3
unseal_if_needed
echo "==> Verifying"
vault_cmd kv get -mount=secret app/db || echo "(sample secret not present in this snapshot)"
echo "==> Restore complete"
