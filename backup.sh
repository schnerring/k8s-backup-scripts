#!/bin/sh

# Constants

BACKUP_FILE_MAX_AGE_DAYS=30

REMARK_POD_LABEL="app=remark42"
REMARK_NAMESPACE="remark42"
REMARK_BACKUP_DIR="/mnt/backup-k8s/remark42"

POSTGRES_POD_LABEL="app=postgres"
POSTGRES_NAMESPACE="postgres"
POSTGRES_BACKUP_DIR="/mnt/backup-k8s/postgres"

MATRIX_POD_LABEL="app=matrix"
MATRIX_NAMESPACE="matrix"
MATRIX_BACKUP_DIR="/mnt/backup-k8s/matrix_media"

##################################################
# Cleanup files older than BACKUP_FILE_MAX_AGE_DAYS days.
# from BACKUP_DIR
# Globals:
#   BACKUP_FILE_MAX_AGE_DAYS
# Arguments:
#   Directory to clean
##################################################
cleanup() {
  find "$1" -mtime "+${BACKUP_FILE_MAX_AGE_DAYS}" -type f -delete
}

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
# Backup all Postgres databases.
# Globals:
#   POSTGRES_POD_LABEL
#   POSTGRES_NAMESPACE
#   POSTGRES_BACKUP_DIR
# Arguments:
#   None
##################################################
backup_postgres() {
  mkdir -p "${POSTGRES_BACKUP_DIR}"
  pod=$(kubectl get pod -l "${POSTGRES_POD_LABEL}" -n "${POSTGRES_NAMESPACE}" -o name)
  kubectl exec -it -n "${POSTGRES_NAMESPACE}" "$pod" -- pg_dumpall | gzip > "${POSTGRES_BACKUP_DIR}/pg_dumpall_$(date +%y%m%d).sql.gz"
}

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
  pod=$(kubectl get pod -l "${MATRIX_POD_LABEL}" -n "${MATRIX_NAMESPACE}" -o name)
  kubectl cp "${MATRIX_NAMESPACE}/${pod}:/data/media_store" "${MATRIX_BACKUP_DIR}/media_store_$(date +%y%m%d)"
}

##################################################
# Main function of script.
# Globals:
#   REMARK_BACKUP_DIR
#   POSTGRES_BACKUP_DIR
#   MATRIX_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  backup_remark42 || exit 1
  cleanup "${REMARK_BACKUP_DIR}" || exit 1

  backup_postgres || exit 1
  cleanup "${POSTGRES_BACKUP_DIR}" || exit 1

  backup_matrix_media || exit 1
  cleanup "${MATRIX_BACKUP_DIR}"
}

# Entrypoint
main
