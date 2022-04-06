#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

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
  pod=$(get_pod_name "${POSTGRES_LABEL}" "${POSTGRES_NAMESPACE}")
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_dump -Fc "${PLAUSIBLE_DB}" >"${PLAUSIBLE_BACKUP_DIR}/$(date +%y%m%d)-postgres-${PLAUSIBLE_DB}.dump"
}

##################################################
# Backup Plausible ClickHouse event database.
# Globals:
#   PLAUSIBLE_BACKUP_DIR
#   PLAUSIBLE_EVENT_DATA_LABEL
#   PLAUSIBLE_NAMESPACE
# Arguments:
#   None
##################################################
backup_clickhouse() {
  echo "Backing up ClickHouse ..."

  mkdir -p "${PLAUSIBLE_BACKUP_DIR}"
  pod=$(get_pod_name "${PLAUSIBLE_EVENT_DATA_LABEL}" "${PLAUSIBLE_NAMESPACE}")

  install_clickhouse_backup

  backup_name=$(date +%y%m%d)-clickhouse

  # Create backup in pod
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    clickhouse-backup create "${backup_name}"

  # Download backup from pod
  tmp="${PLAUSIBLE_BACKUP_DIR}/tmp"
  kubectl cp "${PLAUSIBLE_NAMESPACE}/${pod}:/var/lib/clickhouse/backup/${backup_name}" "${tmp}"
  tar -zcvf "${PLAUSIBLE_BACKUP_DIR}/${backup_name}.tar.gz" "${tmp}"
  rm -rf "${tmp}"

  # Delete backup in pod
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    clickhouse-backup delete local "${backup_name}"
}

##################################################
# Main function of script.
# Globals:
#   PLAUSIBLE_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  echo "Backing up Plausible ..."

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
