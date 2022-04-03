#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/cleanup.sh"

# Constants

POSTGRES_POD_LABEL="app=postgres"
POSTGRES_NAMESPACE="postgres"
POSTGRES_BACKUP_DIR="/mnt/backup-k8s/postgres"

MATRIX_POD_LABEL="app=matrix"
MATRIX_NAMESPACE="matrix"
MATRIX_BACKUP_DIR="/mnt/backup-k8s/matrix"

PLAUSIBLE_EVENT_DATA_POD_LABEL="app=event-data"
PLAUSIBLE_NAMESPACE="plausible"
PLAUSIBLE_BACKUP_DIR="/mnt/backup-k8s/plausible"
CLICKHOUSE_BACKUP_VERSION="1.3.1"

##################################################
# Backup all Postgres databases.
# Globals:
#   POSTGRES_POD_LABEL
#   POSTGRES_NAMESPACE
#   POSTGRES_BACKUP_DIR
# Arguments:
#   None
##################################################
backup_postgres() {
  mkdir -p "${POSTGRES_BACKUP_DIR}"
  pod=$(kubectl get pod -l "${POSTGRES_POD_LABEL}" -n "${POSTGRES_NAMESPACE}" -o name)
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_dumpall | gzip > "${POSTGRES_BACKUP_DIR}/pg_dumpall_$(date +%y%m%d).sql.gz"
}

##################################################
# Backup Matrix (Synapse) media files.
# Globals:
#   MATRIX_POD_LABEL
#   MATRIX_NAMESPACE
#   MATRIX_BACKUP_DIR
# Arguments:
#   None
##################################################
backup_matrix() {
  mkdir -p "${MATRIX_BACKUP_DIR}"
  pod=$(kubectl get pod -l "${MATRIX_POD_LABEL}" -n "${MATRIX_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")
  tmp="${MATRIX_BACKUP_DIR}/tmp"
  kubectl cp "${MATRIX_NAMESPACE}/${pod}:/data/media_store" "${tmp}"
  tar -zcvf "${MATRIX_BACKUP_DIR}/media_store_$(date +%y%m%d).tar.gz" "${tmp}"
  rm -rf "${tmp}"
}

##################################################
# Backup Plausible Clickhouse event database.
# Globals:
#   PLAUSIBLE_EVENT_DATA_POD_LABEL
#   PLAUSIBLE_NAMESPACE
#   PLAUSIBLE_BACKUP_DIR
#   CLICKHOUSE_BACKUP_VERSION
# Arguments:
#   None
##################################################
backup_plausible() {
  mkdir -p "${PLAUSIBLE_BACKUP_DIR}"
  pod=$(kubectl get pod -l "${PLAUSIBLE_EVENT_DATA_POD_LABEL}" -n "${PLAUSIBLE_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")

  # Check if clickhouse-backup was already downloaded
  if kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    wget \
      --quiet \
      --continue \
      --no-clobber \
      --output-document=/tmp/clickhouse-backup.tar.gz \
      "https://github.com/AlexAkulov/clickhouse-backup/releases/download/v${CLICKHOUSE_BACKUP_VERSION}/clickhouse-backup-linux-amd64.tar.gz" 2> /dev/null; then

    # Extract clickhouse-backup to /tmp
    kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
      tar -zxvf /tmp/clickhouse-backup.tar.gz --directory=/tmp --strip-components=3
  fi

  backup_name=clickhouse-backup_$(date +%y%m%d)

  # Create backup in pod
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    /tmp/clickhouse-backup create "${backup_name}"

  # Download backup from pod
  tmp="${PLAUSIBLE_BACKUP_DIR}/tmp"
  kubectl cp "${PLAUSIBLE_NAMESPACE}/${pod}:/var/lib/clickhouse/backup/${backup_name}" "${tmp}"
  tar -zcvf "${PLAUSIBLE_BACKUP_DIR}/${backup_name}.tar.gz" "${tmp}"
  rm -rf "${tmp}"

  # Delete backup in pod
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    /tmp/clickhouse-backup delete local "${backup_name}"
}

##################################################
# Main function of script.
# Globals:
#   POSTGRES_BACKUP_DIR
#   MATRIX_BACKUP_DIR
#   PLAUSIBLE_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  backup_postgres || exit 1
  cleanup "${POSTGRES_BACKUP_DIR}" || exit 1

  backup_matrix || exit 1
  cleanup "${MATRIX_BACKUP_DIR}" || exit 1

  backup_plausible || exit 1
  cleanup "${PLAUSIBLE_BACKUP_DIR}" || exit 1
}

# Entrypoint
main
