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

  echo "Restoring database: ${MATRIX_DB} ..."
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_restore --clean --dbname="${MATRIX_DB}" <"${backup_source_path}"
}

##################################################
# Restore Matrix Synapse media files.
# Globals:
#   MATRIX_BACKUP_DIR
#   MATRIX_LABEL
#   MATRIX_NAMESPACE
# Arguments:
#   None
##################################################
restore_media() {
  echo "Restoring media ..."

  # Get latest media backup
  backup_source_path=$(find "${MATRIX_BACKUP_DIR}" -name '*media.tar.gz' | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  tmp="${MATRIX_BACKUP_DIR}/tmp"
  mkdir -p "${tmp}"
  echo "Extracting ${backup_source_path} to ${tmp} ..."
  tar -xf "${backup_source_path}" -C "${tmp}"

  pod=$(get_pod_name "${MATRIX_LABEL}" "${MATRIX_NAMESPACE}")
  media_path_new="${MATRIX_NAMESPACE}/${pod}:/data/media_store_new"
  echo "Copying ${tmp} to ${media_path_new} ..."
  kubectl cp "${tmp}" "${media_path_new}"

  echo "Restoring backup ..."
  media_path_old="${MATRIX_NAMESPACE}/${pod}:/data/media_store"
  #kubectl exec -i -n "${MATRIX_NAMESPACE}" "$pod" -- \
  #  rm -rf "${media_path_old}"
  #kubectl exec -i -n "${MATRIX_NAMESPACE}" "$pod" -- \
  #  mv "${media_path_new}" "${media_path_old}"
  kubectl exec -i -n "${MATRIX_NAMESPACE}" "$pod" -- \
    ls -alh "${media_path_old}"
  kubectl exec -i -n "${MATRIX_NAMESPACE}" "$pod" -- \
    ls -alh "${media_path_new}"

  echo "Cleaning up ..."
  rm -rf "${tmp}"
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
  restore_media
  echo "Success."
}

# Entrypoint
main
