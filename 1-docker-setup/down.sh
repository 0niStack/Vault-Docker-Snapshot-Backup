#!/usr/bin/env bash
# ./down.sh        -> stop, keep data
# ./down.sh -v     -> stop and DELETE data volume
set -euo pipefail
cd "$(dirname "$0")"
docker compose down "$@"
