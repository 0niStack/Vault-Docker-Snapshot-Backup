#!/usr/bin/env bash
# Test helper: delete the sample secrets so you can prove the restore works.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
need docker jq
for p in app/db app/api app/smtp; do
  vault_cmd kv metadata delete -mount=secret "$p"
done
echo "Sample secrets deleted. Now run ./restore.sh"
