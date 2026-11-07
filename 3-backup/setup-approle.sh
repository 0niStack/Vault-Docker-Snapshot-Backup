#!/usr/bin/env bash
# One-time: snapshot policy + AppRole + start the snapshot agent container.
set -euo pipefail
cd "$(dirname "$0")"
source ../lib.sh
need docker jq
unseal_if_needed

echo "==> Policy 'snapshot'"
printf 'path "sys/storage/raft/snapshot" {\n  capabilities = ["read"]\n}\n' \
  | vault_stdin policy write snapshot -

echo "==> AppRole auth + role 'vault-snap-agent'"
vault_cmd auth list -format=json | jq -e 'has("approle/")' >/dev/null || vault_cmd auth enable approle
vault_cmd write auth/approle/role/vault-snap-agent token_ttl=2h token_policies=snapshot

role_id="$(vault_cmd read -format=json auth/approle/role/vault-snap-agent/role-id | jq -r .data.role_id)"
secret_id="$(vault_cmd write -f -format=json auth/approle/role/vault-snap-agent/secret-id | jq -r .data.secret_id)"

umask 077
printf '%s' "$role_id"   > config/snap-roleid
printf '%s' "$secret_id" > config/snap-secretid

echo "==> Starting snapshot agent"
docker compose up -d --force-recreate
sleep 3
docker logs --tail 5 vault-snap-agent || true
echo "==> Agent proxy on http://127.0.0.1:8100 - now run ./backup.sh"
