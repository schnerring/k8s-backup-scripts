#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

##################################################
# Restore Matrix Synapse Postgres database.
# Globals:
#   MATRIX_BACKUP_DIR
#   MATRIX_DB
#   POSTGRES_LABEL
#   POSTGRES_NAMESPACE
# Arguments:
#   None
##################################################
restore_postgres() {
  echo "Restoring Postgres ..."

  pod=$(get_pod_name "${POSTGRES_LABEL}" "${POSTGRES_NAMESPACE}")

  # Get latest Postgres dump
  backup_source_path=$(find "${MATRIX_BACKUP_DIR}" -name "*.dump" | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  # Restore the backup
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_restore --clean --dbname="${MATRIX_DB}" <"${backup_source_path}"
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
  echo "Success."
}

# Entrypoint
main
