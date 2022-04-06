#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/cleanup.sh"

##################################################
# Backup Matrix Synapse Postgres database.
# Globals:
#   POSTGRES_POD_LABEL
#   POSTGRES_NAMESPACE
#   MATRIX_BACKUP_DIR
#   MATRIX_DB_NAME
# Arguments:
#   None
##################################################
backup_database() {
  pod=$(kubectl get pod -l "${POSTGRES_POD_LABEL}" -n "${POSTGRES_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_dump "${MATRIX_DB_NAME}" | gzip > "${MATRIX_BACKUP_DIR}/pg_dump-${MATRIX_DB_NAME}-$(date +%y%m%d).sql.gz"
}

##################################################
# Backup Matrix Synapse media files.
# Globals:
#   MATRIX_POD_LABEL
#   MATRIX_NAMESPACE
#   MATRIX_BACKUP_DIR
# Arguments:
#   None
##################################################
backup_media() {
  pod=$(kubectl get pod -l "${MATRIX_POD_LABEL}" -n "${MATRIX_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")
  tmp="${MATRIX_BACKUP_DIR}/tmp"
  kubectl cp "${MATRIX_NAMESPACE}/${pod}:data/media_store" "${tmp}"
  tar -zcvf "${MATRIX_BACKUP_DIR}/media_store-$(date +%y%m%d).tar.gz" "${tmp}"
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
  mkdir -p "${MATRIX_BACKUP_DIR}"

  if ! backup_database; then
    printf "Synapse database backup failed" 1>&2
    do_cleanup=false
  fi

  if ! backup_media; then
    printf "Synapse media backup failed" 1>&2
    do_cleanup=false
  fi

  if [ "${do_cleanup}" = true ]; then
    cleanup "${MATRIX_BACKUP_DIR}"
  fi
}

# Entrypoint
main
