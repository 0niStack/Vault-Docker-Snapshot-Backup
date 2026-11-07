# HashiCorp Vault Snapshot Backup (Docker)

HashiCorp Vault with Raft integrated storage, plus snapshot backup and restore.
The backup design follows the openbao-snapshot-agent VM guide
(policy -> AppRole -> Vault Agent -> snapshot script -> retention/S3), which works the same on Vault,
adapted to Docker.

```
vault-snapshot-backup/
├── lib.sh                  shared helpers
├── 1-docker-setup/         compose, vault.hcl, setup.sh (start+init+unseal), unseal.sh, down.sh
├── 2-add-data/             add-data.sh (kv-v2 + sample secrets), show-data.sh
├── 3-backup/               setup-approle.sh, agent config/compose, backup.sh, install-cron.sh
└── 4-restore/              restore.sh, disaster.sh (test helper)
```

Requires: docker (compose v2), jq, curl.

## Flow
```bash
chmod +x lib.sh */*.sh

./1-docker-setup/setup.sh        # 1. start Vault, init, unseal (creates init-keys.json)
./2-add-data/add-data.sh         # 2. add sample data
./2-add-data/show-data.sh

./3-backup/setup-approle.sh      # 3. one-time: policy + AppRole + agent container
./3-backup/backup.sh             #    take a snapshot -> 3-backup/snapshots/
./3-backup/install-cron.sh       #    optional: hourly cron

./4-restore/disaster.sh          # 4. (test) delete the data
./4-restore/restore.sh           #    restore latest snapshot
./2-add-data/show-data.sh        #    data is back
```
`make setup | data | approle | backup | cron | disaster | restore` does the same.

## Notes
- Built-in scheduled snapshots (`sys/storage/raft/snapshot-auto`) are Vault Enterprise only, so this uses
  Vault Agent + cron, which works on the free edition.
- The agent runs in a container and exposes a localhost-only proxy (`127.0.0.1:8100`); `backup.sh` uses `curl` on
  `/v1/sys/storage/raft/snapshot` (the endpoint behind `vault operator raft snapshot save`).
- **init-keys.json** holds the unseal key + root token. Lab only: 1 share / threshold 1.
  Use `KEY_SHARES=5 KEY_THRESHOLD=3 ./1-docker-setup/setup.sh` and store keys offline for real use.
- A snapshot does **not** contain the unseal keys. Restoring onto a brand-new cluster needs the unseal keys
  (and root token) of the cluster the snapshot came from - keep them separately.
- Retention: `RETENTION_DAYS=14 ./backup.sh`. S3 copy: `S3_BUCKET=raft-snapshots ./backup.sh` (s3cmd configured).
- Snapshots contain all your secrets. Protect them and copy them off-host.
- Agent tokens have a 2h TTL and are renewed by the agent. If you recreate the cluster, re-run `setup-approle.sh`.
- TLS is disabled for the lab. Enable it on the listener (and use `https` in the agent config) for production.
