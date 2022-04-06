# k8s-backup-scripts

Scripts that I use for TrueNAS jail cron jobs to backup my Azure Kubernetes Service data.

## Backup

- [backup-remark42.sh](./backup-remark42.sh)  
  Download automatic Remark42 backups.
- [backup-postgres.sh](./backup-postgres.sh)  
  Download all PostgreSQL databases. This includes Matrix and Plausible databases.
- [backup-matrix.sh](./backup-matrix.sh)  
  Download Matrix (Synapse) media files.
- [backup-plausible.sh](./backup-plausible.sh)  
  Download Plausible ClickHouse event database.

Add the following with `crontab -e` to run the backup scripts daily at 02:30 AM:

```shell
KUBECONFIG=/path/to/kubeconfig

REMARK_LABEL="app=remark42"
REMARK_NAMESPACE="remark42"
REMARK_BACKUP_DIR="/mnt/backup-k8s/remark42"

30 2 * * * /path/to/repo/backup-remark42.sh 1> /path/to/logs/backup-remark42.log 2> /path/to/logs/backup-remark42.error

POSTGRES_LABEL="app=postgres"
POSTGRES_NAMESPACE="postgres"

MATRIX_LABEL="app=matrix"
MATRIX_NAMESPACE="matrix"
MATRIX_BACKUP_DIR="/mnt/backup-k8s/matrix"
MATRIX_DB="synapse"

30 2 * * * /path/to/repo/backup-matrix.sh 1> /path/to/logs/backup-matrix.log 2> /path/to/logs/backup-matrix.error

PLAUSIBLE_EVENT_DATA_LABEL="app=event-data"
PLAUSIBLE_NAMESPACE="plausible"
PLAUSIBLE_BACKUP_DIR="/mnt/backup-k8s/plausible"

30 2 * * * /path/to/repo/backup-plausible.sh 1> /path/to/logs/backup-plausible.log 2> /path/to/logs/backup-plausible.error
```

## Restore

- [restore-remark42.sh](./restore-remark42.sh)  
  Upload the latest backup to the Remark42 pod and restore it.

```shell
setenv KUBECONFIG /mnt/backup-k8s/.kube/config

setenv REMARK_LABEL app=remark42
setenv REMARK_NAMESPACE remark42
setenv REMARK_BACKUP_DIR /mnt/backup-k8s/remark42

./restore-remark42.sh

setenv POSTGRES_LABEL app=postgres
setenv POSTGRES_NAMESPACE postgres

setenv MATRIX_LABEL app=matrix
setenv MATRIX_NAMESPACE matrix
setenv MATRIX_DB synapse
setenv MATRIX_BACKUP_DIR /mnt/backup-k8s/matrix
```
