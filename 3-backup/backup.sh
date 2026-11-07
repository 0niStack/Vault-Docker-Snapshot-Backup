#!/usr/bin/env bash
# Take a Raft snapshot through the agent proxy, apply retention, optional S3 sync.
#   RETENTION_DAYS=7           local retention
#   S3_BUCKET=raft-snapshots   (optional, needs s3cmd configured)
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SNAP_DIR="${SNAP_DIR:-$DIR/snapshots}"
AGENT_URL="${AGENT_URL:-http://127.0.0.1:8100}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

mkdir -p "$SNAP_DIR"
OUT="$SNAP_DIR/vault-raft_$(date +%F-%H%M%S).snapshot"

# Large DBs may need a longer timeout (like VAULT_CLIENT_TIMEOUT in the docs)
curl -fsS --max-time "${TIMEOUT:-300}" "$AGENT_URL/v1/sys/storage/raft/snapshot" -o "$OUT.tmp"
[ -s "$OUT.tmp" ] || { rm -f "$OUT.tmp"; echo "ERROR: empty snapshot" >&2; exit 1; }
mv "$OUT.tmp" "$OUT"
echo "Snapshot saved: $OUT ($(du -h "$OUT" | cut -f1))"

# Retention (local only)
find "$SNAP_DIR" -name 'vault-raft_*.snapshot' -mtime +"$RETENTION_DAYS" -delete

# Optional remote copy
if [ -n "${S3_BUCKET:-}" ]; then
  if command -v s3cmd >/dev/null; then
    s3cmd sync "$SNAP_DIR/" "s3://$S3_BUCKET/"
  else
    echo "WARN: s3cmd not found, skipping S3 sync" >&2
  fi
fi
