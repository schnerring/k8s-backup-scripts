#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/cleanup.sh"

##################################################
# Backup Matrix (Synapse) media files.
# Globals:
#   MATRIX_POD_LABEL
#   MATRIX_NAMESPACE
#   MATRIX_BACKUP_DIR
# Arguments:
#   None
##################################################
backup_matrix() {
  mkdir -p "${MATRIX_BACKUP_DIR}"
  pod=$(kubectl get pod -l "${MATRIX_POD_LABEL}" -n "${MATRIX_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")
  tmp="${MATRIX_BACKUP_DIR}/tmp"
  kubectl cp "${MATRIX_NAMESPACE}/${pod}:/data/media_store" "${tmp}"
  tar -zcvf "${MATRIX_BACKUP_DIR}/media_store_$(date +%y%m%d).tar.gz" "${tmp}"
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
  backup_matrix || exit 1
  cleanup "${MATRIX_BACKUP_DIR}" || exit 1
}

# Entrypoint
main
