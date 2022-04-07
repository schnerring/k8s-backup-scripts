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
  backup_source_path=$(find "${PLAUSIBLE_BACKUP_DIR}" -name "*-postgres-${PLAUSIBLE_DB}.dump" | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  # Restore the backup
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

  backup_filename=$(basename "${backup_source_path}")

  echo "${backup_filename}"
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
}

# Entrypoint
main
