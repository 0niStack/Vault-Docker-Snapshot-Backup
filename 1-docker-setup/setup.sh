#!/usr/bin/env bash
# Start HashiCorp Vault, initialise it (first run only) and unseal it.
set -euo pipefail
cd "$(dirname "$0")"
source ../lib.sh
need docker jq

KEY_SHARES="${KEY_SHARES:-1}"        # lab default; use 5/3 in production
KEY_THRESHOLD="${KEY_THRESHOLD:-1}"

echo "==> Starting container"
docker compose up -d

echo "==> Waiting for HashiCorp Vault API"
out=""
for _ in $(seq 1 60); do
  out="$(vault_anon status -format=json 2>/dev/null || true)"
  [ -n "$out" ] && break
  sleep 1
done
[ -n "$out" ] || { echo "ERROR: HashiCorp Vault did not come up (docker logs vault)" >&2; exit 1; }

if [ "$(echo "$out" | jq -r .initialized)" != "true" ]; then
  echo "==> Initialising ($KEY_SHARES shares / threshold $KEY_THRESHOLD)"
  vault_anon operator init -key-shares="$KEY_SHARES" -key-threshold="$KEY_THRESHOLD" -format=json > "$INIT_FILE"
  chmod 600 "$INIT_FILE"
  echo "    unseal keys + root token saved to 1-docker-setup/init-keys.json (KEEP THIS SAFE)"
fi

unseal_if_needed
vault_anon status || true
echo "==> Ready: http://127.0.0.1:8200"
