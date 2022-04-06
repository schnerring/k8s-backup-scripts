#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

##################################################
# Copy backup to Remark42 pod and restore it.
# Globals:
#   REMARK_LABEL
#   REMARK_NAMESPACE
#   REMARK_BACKUP_DIR
# Arguments:
#   None
##################################################
restore_remark42() {
  pod=$(get_pod_name "${REMARK_LABEL}" "${REMARK_NAMESPACE}")

  # Get latest backup
  backup_source_path=$(find "${REMARK_BACKUP_DIR}" | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  # Copy backup to pod
  backup_filename=$(basename "${backup_source_path}")
  backup_destination_path=/var/backup/${backup_filename}
  kubectl cp "${backup_source_path}" "${REMARK_NAMESPACE}/${pod}:${backup_destination_path}"

  # Extract site from filename
  # E.g., `schnerring.net` from `backup-schnerring.net-20220403.gz`
  site=$(printf '%s' "${backup_filename}" | awk -F'-' '{ print $2 }')

  # TODO create user backup before restore

  # Restore the backup
  kubectl exec -i "${pod}" -n "${REMARK_NAMESPACE}" -- \
    remark42 restore --site "${site}" --file "${backup_destination_path}"
}

##################################################
# Main function of script.
# Globals:
#   REMARK_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  restore_remark42 || exit 1
}

# Entrypoint
main
