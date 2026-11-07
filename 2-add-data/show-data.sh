#!/usr/bin/env bash
# List and read the sample secrets (compare before/after restore).
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
need docker jq
vault_cmd kv list -mount=secret app
for p in app/db app/api app/smtp; do
  echo "--- secret/$p"
  vault_cmd kv get -mount=secret "$p"
done
