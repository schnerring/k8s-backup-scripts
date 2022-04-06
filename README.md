# k8s-backup-scripts

Scripts that I use for TrueNAS jail cron jobs to backup my Azure Kubernetes Service data.

## Backup

- [backup-remark42.sh](./backup-remark42.sh)  
  Download automatic Remark42 backups.
- [backup-matrix.sh](./backup-matrix.sh)  
  Back Matrix (Synapse) Postgres database and media repository.
- [backup-plausible.sh](./backup-plausible.sh)  
  Download Plausible Postgres database and ClickHouse database.

Add the following with `crontab -e` to run the backup scripts daily at 02:30 AM:

```shell
KUBECONFIG=/path/to/kubeconfig

REMARK_BACKUP_DIR="/mnt/backup-k8s/remark42"
REMARK_LABEL="app=remark42"
REMARK_NAMESPACE="remark42"

30 2 * * * /mnt/backup-k8s/scripts/backup-remark42.sh >/mnt/backup-k8s/log/remark42.txt 2>&1

POSTGRES_LABEL="app=postgres"
POSTGRES_NAMESPACE="postgres"

MATRIX_BACKUP_DIR="/mnt/backup-k8s/matrix"
MATRIX_DB="synapse"
MATRIX_LABEL="app=matrix"
MATRIX_NAMESPACE="matrix"

30 2 * * * /mnt/backup-k8s/scripts/backup-matrix.sh >/mnt/backup-k8s/log/matrix.txt 2>&1

PLAUSIBLE_BACKUP_DIR="/mnt/backup-k8s/plausible"
PLAUSIBLE_DB="plausible"
PLAUSIBLE_EVENT_DATA_LABEL="app=event-data"
PLAUSIBLE_NAMESPACE="plausible"

30 2 * * * /mnt/backup-k8s/scripts/backup-plausible.sh >/mnt/backup-k8s/log/plausible.txt 2>&1
```

## Restore

- [restore-remark42.sh](./restore-remark42.sh)  
  Upload the latest backup to the Remark42 pod and restore it.

```shell
setenv KUBECONFIG /mnt/backup-k8s/.kube/config

setenv REMARK_BACKUP_DIR /mnt/backup-k8s/remark42
setenv REMARK_LABEL app=remark42
setenv REMARK_NAMESPACE remark42

./restore-remark42.sh

setenv POSTGRES_LABEL app=postgres
setenv POSTGRES_NAMESPACE postgres

setenv MATRIX_BACKUP_DIR /mnt/backup-k8s/matrix
setenv MATRIX_DB synapse
setenv MATRIX_LABEL app=matrix
setenv MATRIX_NAMESPACE matrix

setenv PLAUSIBLE_BACKUP_DIR /mnt/backup-k8s/plausible
setenv PLAUSIBLE_DB plausible
setenv PLAUSIBLE_EVENT_DATA_LABEL app=event-data
setenv PLAUSIBLE_NAMESPACE plausible
```
