#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

##################################################
# Copy latest backup file to Remark42 pod and restore it.
# Globals:
#   REMARK_BACKUP_DIR
#   REMARK_LABEL
#   REMARK_NAMESPACE
# Arguments:
#   None
##################################################
restore_backup() {
  echo "Restoring Remark42 backup ..."

  pod=$(get_pod_name "${REMARK_LABEL}" "${REMARK_NAMESPACE}")

  # Get latest backup
  backup_source_path=$(find "${REMARK_BACKUP_DIR}" -name 'backup*.gz' | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  # Copy backup to pod
  backup_filename=$(basename "${backup_source_path}")
  backup_destination_path=var/backup/${backup_filename}
  kubectl cp "${backup_source_path}" "${REMARK_NAMESPACE}/${pod}:${backup_destination_path}"

  # Extract site from filename
  # E.g., `schnerring.net` from `backup-schnerring.net-20220403.gz`
  site=$(printf '%s' "${backup_filename}" | awk -F'-' '{ print $2 }')

  # TODO maybe create user backup before restore

  # Restore the backup
  kubectl exec -i "${pod}" -n "${REMARK_NAMESPACE}" -- \
    remark42 restore --site "${site}" --file "${backup_destination_path}"
}

##################################################
# Restore Remark42 avatar files.
# Globals:
#   REMARK_BACKUP_DIR
#   REMARK_LABEL
#   REMARK_NAMESPACE
# Arguments:
#   None
##################################################
restore_avatars() {
  echo "Restoring Remark42 avatar files ..."

  # Get latest avatars backup
  backup_source_path=$(find "${REMARK_BACKUP_DIR}" -name '*avatars.tar.gz' | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  tmp="${REMARK_BACKUP_DIR}/avatars"
  mkdir -p "${tmp}"
  echo "Extracting ${backup_source_path} to ${tmp} ..."
  tar -xf "${backup_source_path}" -C "${tmp}"

  pod=$(get_pod_name "${REMARK_LABEL}" "${REMARK_NAMESPACE}")
  pod_path="${REMARK_NAMESPACE}/${pod}:var"
  echo "Copying ${tmp} to ${pod_path} ..."
  kubectl cp "${tmp}" "${pod_path}"

  echo "Cleaning up ..."
  rm -rf "${tmp}"
}

##################################################
# Restore Remark42 image files.
# Globals:
#   REMARK_BACKUP_DIR
#   REMARK_LABEL
#   REMARK_NAMESPACE
# Arguments:
#   None
##################################################
restore_images() {
  echo "Restoring Remark42 image files ..."

  # Get latest images backup
  backup_source_path=$(find "${REMARK_BACKUP_DIR}" -name '*images.tar.gz' | sort | tail -n1)

  # Confirmation prompt
  confirm "${backup_source_path}"

  tmp="${REMARK_BACKUP_DIR}/pictures"
  mkdir -p "${tmp}"
  echo "Extracting ${backup_source_path} to ${tmp} ..."
  tar -xf "${backup_source_path}" -C "${tmp}"

  pod=$(get_pod_name "${REMARK_LABEL}" "${REMARK_NAMESPACE}")
  pod_path="${REMARK_NAMESPACE}/${pod}:var"
  echo "Copying ${tmp} to ${pod_path} ..."
  kubectl cp "${tmp}" "${pod_path}"

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
  restore_backup
  restore_avatars
  restore_images
  echo "Success."
}

# Entrypoint
main
