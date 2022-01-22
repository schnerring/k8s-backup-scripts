#!/bin/sh

BACKUP_FILE_MAX_AGE_DAYS=30

##################################################
# Clean files older than BACKUP_FILE_MAX_AGE_DAYS days.
# from BACKUP_DIR
# Globals:
#   BACKUP_FILE_MAX_AGE_DAYS
# Arguments:
#   Directory to clean
##################################################
cleanup() {
  find "$1" -mtime "+${BACKUP_FILE_MAX_AGE_DAYS}" -type f -delete
}

REMARK_POD_LABEL="app=remark42"
REMARK_NAMESPACE="remark42"
REMARK_BACKUP_DIR="/mnt/backup-k8s/remark42"

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
  cleanup "${REMARK_BACKUP_DIR}" || exit 1
}

# Entrypoint
main
