#!/usr/bin/env bash
# Shared helpers - sourced by every script in the 4 folders.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER="${VAULT_CONTAINER:-vault}"
INIT_FILE="$ROOT_DIR/1-docker-setup/init-keys.json"
VAULT_ADDR_IN="http://127.0.0.1:8200"   # address *inside* the container

need() {
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || { echo "ERROR: '$c' is required" >&2; exit 1; }
  done
}

root_token() {
  [ -f "$INIT_FILE" ] || { echo "ERROR: $INIT_FILE not found - run 1-docker-setup/setup.sh first" >&2; exit 1; }
  jq -r .root_token "$INIT_FILE"
}

# vault without a token (status / init / unseal)
vault_anon()  { docker exec -e VAULT_ADDR="$VAULT_ADDR_IN" "$CONTAINER" vault "$@"; }
# vault with the root token
vault_cmd()   { docker exec -e VAULT_ADDR="$VAULT_ADDR_IN" -e VAULT_TOKEN="$(root_token)" "$CONTAINER" vault "$@"; }
# same, but forwards stdin (e.g. policy write NAME -)
vault_stdin() { docker exec -i -e VAULT_ADDR="$VAULT_ADDR_IN" -e VAULT_TOKEN="$(root_token)" "$CONTAINER" vault "$@"; }

is_sealed() { vault_anon status -format=json 2>/dev/null | jq -r .sealed || true; }

unseal_if_needed() {
  if [ "$(is_sealed)" = "true" ]; then
    echo "==> Unsealing HashiCorp Vault"
    for k in $(jq -r '.unseal_keys_b64[]' "$INIT_FILE"); do
      vault_anon operator unseal "$k" >/dev/null
      [ "$(is_sealed)" = "false" ] && break
    done
  fi
  return 0
}
