#!/usr/bin/env bash
# Enable the KV v2 engine and write some sample secrets.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
need docker jq
unseal_if_needed

if ! vault_cmd secrets list -format=json | jq -e 'has("secret/")' >/dev/null; then
  echo "==> Enabling kv-v2 at secret/"
  vault_cmd secrets enable -path=secret kv-v2
fi

echo "==> Writing sample secrets"
vault_cmd kv put -mount=secret app/db    username=appuser password='S3cr3t-DB-pass' host=db.internal
vault_cmd kv put -mount=secret app/api   key=abc123-api-key
vault_cmd kv put -mount=secret app/smtp  user=mailer password='smtp-pass'

echo "==> Done. Run ./show-data.sh to read them back."
