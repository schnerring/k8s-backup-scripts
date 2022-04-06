#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/common.sh"

##################################################
# Copy automatic Remark42 backup files from pod.
# Globals:
#   REMARK_BACKUP_DIR
#   REMARK_LABEL
#   REMARK_NAMESPACE
# Arguments:
#   None
##################################################
download_backups() {
  mkdir -p "${REMARK_BACKUP_DIR}"
  pod=$(get_pod_name "${REMARK_LABEL}" "${REMARK_NAMESPACE}")
  kubectl cp "${REMARK_NAMESPACE}/${pod}:/var/backup" "${REMARK_BACKUP_DIR}"
}

##################################################
# Main function of script.
# Globals:
#   REMARK_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  echo "Backing up Remark42 ..."

  if ! download_backups; then
    echo "Downloading backups failed." >&2
    success=false
  fi

  if [ "${success}" = false ]; then
    exit 1
  fi

  cleanup "${REMARK_BACKUP_DIR}"
  echo "Success."
}

# Entrypoint
main
