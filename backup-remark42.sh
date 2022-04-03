#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/cleanup.sh"

##################################################
# Copy automatic Remark42 backup files from pod.
# Globals:
#   REMARK_POD_LABEL
#   REMARK_NAMESPACE
#   REMARK_BACKUP_DIR
# Arguments:
#   None
##################################################
backup_remark42() {
  mkdir -p "${REMARK_BACKUP_DIR}"
  # -o name doesn't work because "kubectl cp" doesn't support the "pod/" prefix
  pod=$(kubectl get pod -l "${REMARK_POD_LABEL}" -n "${REMARK_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")
  kubectl cp "${REMARK_NAMESPACE}/${pod}:var/backup" "${REMARK_BACKUP_DIR}"
}

##################################################
# Main function of script.
# Globals:
#   REMARK_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  backup_remark42 || exit 1
  cleanup "${REMARK_BACKUP_DIR}"
}

# Entrypoint
main
