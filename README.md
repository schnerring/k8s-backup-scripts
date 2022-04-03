# k8s-backup-scripts

Scripts that I use for TrueNAS jail cron jobs to backup my Azure Kubernetes Service data.

- [backup-remark42.sh](./backup-remark42.sh)  
  Download automatic Remark42 backups.
- [backup-postgres.sh](./backup-postgres.sh)  
  Download all PostgreSQL databases. This includes Matrix and Plausible databases.
- [backup-matrix.sh](./backup-matrix.sh)  
  Download Matrix (Synapse) media files.
- [backup-plausible.sh](./backup-plausible.sh)  
  Download Plausible ClickHouse event database.

## Backup

Add the following to with `crontab -e` to run the backup scripts daily at 02:30 AM:

```shell
KUBECONFIG=/path/to/kubeconfig

REMARK_POD_LABEL="app=remark42"
REMARK_NAMESPACE="remark42"
REMARK_BACKUP_DIR="/mnt/backup-k8s/remark42"

30 2 * * * /path/to/repo/backup-remark42.sh 1> /path/to/logs/backup-remark42.log 2> /path/to/logs/backup-remark42.error

POSTGRES_POD_LABEL="app=postgres"
POSTGRES_NAMESPACE="postgres"
POSTGRES_BACKUP_DIR="/mnt/backup-k8s/postgres"

30 2 * * * /path/to/repo/backup-postgres.sh 1> /path/to/logs/backup-postgres.log 2> /path/to/logs/backup-postgres.error

MATRIX_POD_LABEL="app=matrix"
MATRIX_NAMESPACE="matrix"
MATRIX_BACKUP_DIR="/mnt/backup-k8s/matrix"

30 2 * * * /path/to/repo/backup-matrix.sh 1> /path/to/logs/backup-matrix.log 2> /path/to/logs/backup-matrix.error

PLAUSIBLE_EVENT_DATA_POD_LABEL="app=event-data"
PLAUSIBLE_NAMESPACE="plausible"
PLAUSIBLE_BACKUP_DIR="/mnt/backup-k8s/plausible"

30 2 * * * /path/to/repo/backup-plausible.sh 1> /path/to/logs/backup-plausible.log 2> /path/to/logs/backup-plausible.error
```

## Recovery

TODO
