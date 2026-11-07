#!/usr/bin/env bash
# Unseal after a container/host restart.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
need docker jq
unseal_if_needed
vault_anon status
