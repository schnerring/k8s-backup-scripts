#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

##################################################
# Restore Plausible Postgres database.
# Globals:
#   PLAUSIBLE_BACKUP_DIR
#   PLAUSIBLE_DB
#   POSTGRES_LABEL
#   POSTGRES_NAMESPACE
# Arguments:
#   None
##################################################
restore_postgres() {
  echo "Restoring Postgres ..."

  pod=$(get_pod_name "${POSTGRES_LABEL}" "${POSTGRES_NAMESPACE}")

  # Get latest Postgres dump
  backup_source_path=$(find "${PLAUSIBLE_BACKUP_DIR}" -name "*.dump" | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  echo "Restoring database: ${PLAUSIBLE_DB} ..."
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_restore --clean --dbname="${PLAUSIBLE_DB}" <"${backup_source_path}"
}

##################################################
# Restore Plausible ClickHouse database.
# Globals:
#   PLAUSIBLE_LABEL
#   PLAUSIBLE_NAMESPACE
#   PLAUSIBLE_BACKUP_DIR
# Arguments:
#   None
##################################################
restore_clickhouse() {
  echo "Restoring ClickHouse ..."

  # Get latest ClickHouse backup
  backup_source_path=$(find "${PLAUSIBLE_BACKUP_DIR}" -name '*clickhouse.tar.gz' | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  install_clickhouse_backup

  tmp="${PLAUSIBLE_BACKUP_DIR}/tmp"
  mkdir -p "${tmp}"
  echo "Extracting ${backup_source_path} to ${tmp} ..."
  tar -xf "${backup_source_path}" -C "${tmp}"

  pod=$(get_pod_name "${PLAUSIBLE_EVENT_DATA_LABEL}" "${PLAUSIBLE_NAMESPACE}")
  backup_name=$(basename "${backup_source_path}" .tar.gz)
  backup_destination_path=/var/lib/clickhouse/backup/${backup_name}
  pod_path="${PLAUSIBLE_NAMESPACE}/${pod}:${backup_destination_path}"
  echo "Copying ${tmp} to ${pod_path} ..."
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    mkdir -p "${backup_destination_path}"
  kubectl cp "${tmp}" "${pod_path}"

  echo "Restoring backup ${backup_name} ..."
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    clickhouse-backup restore "${backup_name}"

  echo "Cleaning up ..."
  rm -rf "${tmp}"
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    clickhouse-backup delete local "${backup_name}"
}

##################################################
# Main function of script.
# Globals:
#   None
# Arguments:
#   None
##################################################
main() {
  restore_postgres
  restore_clickhouse
  echo "Success."
}

# Entrypoint
main
