#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/cleanup.sh"

##################################################
# Backup all Postgres databases.
# Globals:
#   POSTGRES_BACKUP_DIR
#   POSTGRES_LABEL
#   POSTGRES_NAMESPACE
# Arguments:
#   None
##################################################
backup_postgres() {
  mkdir -p "${POSTGRES_BACKUP_DIR}"
  pod=$(kubectl get pod -l "${POSTGRES_LABEL}" -n "${POSTGRES_NAMESPACE}" -o name)
  kubectl exec -i -n "${POSTGRES_NAMESPACE}" "$pod" -- \
    pg_dumpall | gzip > "${POSTGRES_BACKUP_DIR}/pg_dumpall_$(date +%y%m%d).sql.gz"
}

##################################################
# Main function of script.
# Globals:
#   POSTGRES_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  backup_postgres || exit 1
  cleanup "${POSTGRES_BACKUP_DIR}" || exit 1
}

# Entrypoint
main
