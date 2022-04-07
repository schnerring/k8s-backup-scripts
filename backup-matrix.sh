#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

##################################################
# Backup Matrix Synapse Postgres database.
# Globals:
#   MATRIX_BACKUP_DIR
#   MATRIX_DB
#   POSTGRES_LABEL
#   POSTGRES_NAMESPACE
# Arguments:
#   None
##################################################
backup_database() {
  echo "Backing up database ..."
  pod=$(get_pod_name "${POSTGRES_LABEL}" "${POSTGRES_NAMESPACE}")
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_dump -Fc "${MATRIX_DB}" >"${MATRIX_BACKUP_DIR}/$(date +%y%m%d)-postgres-${MATRIX_DB}.dump"
}

##################################################
# Backup Matrix Synapse media files.
# Globals:
#   MATRIX_BACKUP_DIR
#   MATRIX_LABEL
#   MATRIX_NAMESPACE
# Arguments:
#   None
##################################################
backup_media() {
  echo "Backing up media ..."
  pod=$(get_pod_name "${MATRIX_LABEL}" "${MATRIX_NAMESPACE}")
  tmp="${MATRIX_BACKUP_DIR}/tmp"
  kubectl cp "${MATRIX_NAMESPACE}/${pod}:/data/media_store" "${tmp}"
  tar -zcf "${MATRIX_BACKUP_DIR}/$(date +%y%m%d)-media.tar.gz" -C "${tmp}" .
  rm -rf "${tmp}"
}

##################################################
# Main function of script.
# Globals:
#   MATRIX_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  echo "Backing up Matrix Synapse ..."

  mkdir -p "${MATRIX_BACKUP_DIR}"

  if ! backup_database; then
    echo "Database backup failed." >&2
    success=false
  fi

  if ! backup_media; then
    echo "Media backup failed." >&2
    success=false
  fi

  if [ "${success}" = false ]; then
    exit 1
  fi

  cleanup "${MATRIX_BACKUP_DIR}"
  echo "Success."
}

# Entrypoint
main
