#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/cleanup.sh"

NOW=$(date +%y%m%d)

##################################################
# Backup Matrix Synapse Postgres database.
# Globals:
#   POSTGRES_LABEL
#   POSTGRES_NAMESPACE
#   MATRIX_BACKUP_DIR
#   MATRIX_DB
# Arguments:
#   None
##################################################
backup_database() {
  pod=$(kubectl get pod -l "${POSTGRES_LABEL}" -n "${POSTGRES_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_dump "${MATRIX_DB}" | gzip > "${MATRIX_BACKUP_DIR}/${NOW}-${MATRIX_DB}.sql.gz"
}

##################################################
# Backup Matrix Synapse media files.
# Globals:
#   MATRIX_LABEL
#   MATRIX_NAMESPACE
#   MATRIX_BACKUP_DIR
# Arguments:
#   None
##################################################
backup_media() {
  pod=$(kubectl get pod -l "${MATRIX_LABEL}" -n "${MATRIX_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")
  tmp="${MATRIX_BACKUP_DIR}/tmp"
  kubectl cp "${MATRIX_NAMESPACE}/${pod}:/data/media_store" "${tmp}"
  tar -zcvf "${MATRIX_BACKUP_DIR}/${NOW}-media_store.tar.gz" "${tmp}"
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
