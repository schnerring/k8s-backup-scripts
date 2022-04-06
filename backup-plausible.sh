#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

CLICKHOUSE_BACKUP_VERSION="1.3.1"

##################################################
# Backup Plausible Postgres database.
# Globals:
#   PLAUSIBLE_BACKUP_DIR
#   PLAUSIBLE_DB
#   POSTGRES_LABEL
#   POSTGRES_NAMESPACE
# Arguments:
#   None
##################################################
backup_postgres() {
  echo "Backing up Postgres ..."
  pod=$(kubectl get pod -l "${POSTGRES_LABEL}" -n "${POSTGRES_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_dump -Fc "${PLAUSIBLE_DB}" >"${PLAUSIBLE_BACKUP_DIR}/$(date +%y%m%d)-postgres-${PLAUSIBLE_DB}.dump"
}

##################################################
# Backup Plausible ClickHouse event database.
# Globals:
#   CLICKHOUSE_BACKUP_VERSION
#   PLAUSIBLE_BACKUP_DIR
#   PLAUSIBLE_EVENT_DATA_LABEL
#   PLAUSIBLE_NAMESPACE
# Arguments:
#   None
##################################################
backup_clickhouse() {
  echo "Backing up ClickHouse ..."

  mkdir -p "${PLAUSIBLE_BACKUP_DIR}"
  pod=$(kubectl get pod -l "${PLAUSIBLE_EVENT_DATA_LABEL}" -n "${PLAUSIBLE_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")

  # Check if clickhouse-backup was already downloaded
  if kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    wget \
      --quiet \
      --continue \
      --no-clobber \
      --output-document=/tmp/clickhouse-backup.tar.gz \
      "https://github.com/AlexAkulov/clickhouse-backup/releases/download/v${CLICKHOUSE_BACKUP_VERSION}/clickhouse-backup-linux-amd64.tar.gz" 2>/dev/null; then

    # Extract clickhouse-backup to /tmp
    kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
      tar -zxvf /tmp/clickhouse-backup.tar.gz --directory=/tmp --strip-components=3
  fi

  backup_name=$(date +%y%m%d)-clickhouse

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
#   PLAUSIBLE_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  Echo "Backing up Plausible ..."

  if ! backup_postgres; then
    echo "Postgres backup failed." >&2
    success=false
  fi

  if ! backup_clickhouse; then
    echo "ClickHouse backup failed." >&2
    success=false
  fi

  if [ "${success}" = false ]; then
    exit 1
  fi

  cleanup "${PLAUSIBLE_BACKUP_DIR}"
  echo "Success."
}

# Entrypoint
main
