.PHONY: setup data approle backup cron disaster restore
setup:    ; ./1-docker-setup/setup.sh
data:     ; ./2-add-data/add-data.sh
approle:  ; ./3-backup/setup-approle.sh
backup:   ; ./3-backup/backup.sh
cron:     ; ./3-backup/install-cron.sh
disaster: ; ./4-restore/disaster.sh
restore:  ; ./4-restore/restore.sh
