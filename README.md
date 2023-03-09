# k8s-backup-scripts

Scripts that I use for TrueNAS jail cron jobs to backup my Azure Kubernetes Service data.

## Requirements

For Ubuntu Server 22.04.2 LTS the following packages are additionally required:

- `kubectl`, see [Install and Set Up kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- NFS Client: `sudo apt install nfs-common`

## Backup

- [backup-remark42.sh](./backup-remark42.sh)  
  Download automatic Remark42 backups.
- [backup-matrix.sh](./backup-matrix.sh)  
  Back Matrix (Synapse) Postgres database and media repository.
- [backup-plausible.sh](./backup-plausible.sh)  
  Download Plausible Postgres database and ClickHouse database.

Add the following with `crontab -e` to run the backup scripts daily at 02:30 AM:

```shell
KUBECONFIG=/mnt/backup-k8s/.kube/config

REMARK_BACKUP_DIR=/mnt/backup-k8s/remark42
REMARK_LABEL=app=remark42
REMARK_NAMESPACE=remark42

30 2 * * * /mnt/backup-k8s/scripts/backup-remark42.sh >/mnt/backup-k8s/log/remark42.txt 2>&1

POSTGRES_LABEL=app=postgres
POSTGRES_NAMESPACE=postgres

MATRIX_NAMESPACE=matrix
MATRIX_SYNAPSE_BACKUP_DIR=/mnt/backup-k8s/matrix-synapse
MATRIX_SYNAPSE_DB=matrix-synapse
MATRIX_SYNAPSE_LABEL=app=matrix-synapse

30 2 * * * /mnt/backup-k8s/scripts/backup-matrix-synapse.sh >/mnt/backup-k8s/log/matrix-synapse.txt 2>&1

PLAUSIBLE_BACKUP_DIR=/mnt/backup-k8s/plausible
PLAUSIBLE_DB=plausible
PLAUSIBLE_EVENT_DATA_LABEL=app=event-data
PLAUSIBLE_NAMESPACE=plausible

30 2 * * * /mnt/backup-k8s/scripts/backup-plausible.sh >/mnt/backup-k8s/log/plausible.txt 2>&1
```

Set environment variables in `/etc/environment` alternatively.

## Restore

- [restore-remark42.sh](./restore-remark42.sh)  
  Upload the latest backup to the Remark42 pod and restore it.
- [restore-matrix.sh](./restore-matrix.sh)  
  Restore the latest Postgres database and media repository backups of Matrix Synapse.
- [restore-plausible.sh](./restore-matrix.sh)  
  Restore the latest Plausible Postgres database and ClickHouse database backups.

```shell
setenv KUBECONFIG /mnt/backup-k8s/.kube/config

setenv REMARK_BACKUP_DIR /mnt/backup-k8s/remark42
setenv REMARK_LABEL app=remark42
setenv REMARK_NAMESPACE remark42

./restore-remark42.sh

setenv POSTGRES_LABEL app=postgres
setenv POSTGRES_NAMESPACE postgres

setenv MATRIX_NAMESPACE matrix
setenv MATRIX_SYNAPSE_BACKUP_DIR /mnt/backup-k8s/matrix-synapse
setenv MATRIX_SYNAPSE_DB matrix-synapse
setenv MATRIX_SYNAPSE_LABEL app=matrix-synapse

./restore-matrix-synapse.sh

setenv PLAUSIBLE_BACKUP_DIR /mnt/backup-k8s/plausible
setenv PLAUSIBLE_DB plausible
setenv PLAUSIBLE_EVENT_DATA_LABEL app=event-data
setenv PLAUSIBLE_NAMESPACE plausible

./restore-plausible.sh
```
