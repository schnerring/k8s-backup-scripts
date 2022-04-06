#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

##################################################
# Restore Plausible Postgres database.
# Globals:
#   PLAUSIBLE_LABEL
#   PLAUSIBLE_NAMESPACE
#   PLAUSIBLE_BACKUP_DIR
# Arguments:
#   None
##################################################
restore_postgres() {
  echo "Restoring Postgres ..."

  pod=$(get_pod_name "${PLAUSIBLE_LABEL}" "${PLAUSIBLE_NAMESPACE}")

  # Get latest Postgres dump
  backup_source_path=$(find "${PLAUSIBLE_BACKUP_DIR}" -name '*.dump' | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  # Copy backup to pod
  backup_filename=$(basename "${backup_source_path}")

  # Extract database name from filename
  # E.g., `plausible` from `220406-postgres-plausible.dump`
  db=$(printf '%s' "${backup_filename}" | awk -F'-' '{ print $3 }' | awk -F'.' '{ print $1 }')

  # Restore the backup
  echo "${db}"
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
