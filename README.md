# k8s-backup-scripts

Scripts that I use for TrueNAS jail cron jobs to backup my Azure Kubernetes Service data.

## Usage

Add the following to with `crontab -e` to run the backup scripts daily at 02:30 AM:

```shell
REMARK_POD_LABEL="app=remark42"
REMARK_NAMESPACE="remark42"
REMARK_BACKUP_DIR="/mnt/backup-k8s/remark42"

30 2 * * * /path/to/repo/backup-remark42.sh

POSTGRES_POD_LABEL="app=postgres"
POSTGRES_NAMESPACE="postgres"
POSTGRES_BACKUP_DIR="/mnt/backup-k8s/postgres"

30 2 * * * /path/to/repo/backup-postgres.sh

MATRIX_POD_LABEL="app=matrix"
MATRIX_NAMESPACE="matrix"
MATRIX_BACKUP_DIR="/mnt/backup-k8s/matrix"

30 2 * * * /path/to/repo/backup-matrix.sh

PLAUSIBLE_EVENT_DATA_POD_LABEL="app=event-data"
PLAUSIBLE_NAMESPACE="plausible"
PLAUSIBLE_BACKUP_DIR="/mnt/backup-k8s/plausible"
CLICKHOUSE_BACKUP_VERSION="1.3.1"

30 2 * * * /path/to/repo/backup-plausible.sh
```
