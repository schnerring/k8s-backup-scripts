#!/bin/sh

# This script assumes the default Remark42 CLI parameters for:
#
#   - BACKUP_PATH    = ./var/backup
#   - AVATAR_TYPE    = fs
#   - AVATAR_FS_PATH = ./var/avatars
#   - IMAGE_TYPE     = fs
#   - IMAGE_FS_PATH  = ./var/pictures
#
# See also: https://remark42.com/docs/configuration/parameters/

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
  echo "Downloading automatic Remark42 backups ..."
  pod=$(get_pod_name "${REMARK_LABEL}" "${REMARK_NAMESPACE}")
  kubectl cp "${REMARK_NAMESPACE}/${pod}:var/backup" "${REMARK_BACKUP_DIR}"
}

##################################################
# Copy Remark42 avatar files from pod.
# Globals:
#   REMARK_BACKUP_DIR
#   REMARK_LABEL
#   REMARK_NAMESPACE
# Arguments:
#   None
##################################################
backup_avatars() {
  echo "Backing up Remark42 avatars ..."
  pod=$(get_pod_name "${REMARK_LABEL}" "${REMARK_NAMESPACE}")
  tmp="${REMARK_BACKUP_DIR}/tmp"
  kubectl cp "${REMARK_NAMESPACE}/${pod}:var/avatars" "${tmp}"
  tar -zcf "${REMARK_BACKUP_DIR}/$(date +%y%m%d)-avatars.tar.gz" -C "${tmp}" .
  rm -rf "${tmp}"
}

##################################################
# Copy Remark42 image files from pod.
# This function assumes the default Remark42 configuration.
# Globals:
#   REMARK_BACKUP_DIR
#   REMARK_LABEL
#   REMARK_NAMESPACE
# Arguments:
#   None
##################################################
backup_images() {
  echo "Backing up Remark42 images ..."
  pod=$(get_pod_name "${REMARK_LABEL}" "${REMARK_NAMESPACE}")
  tmp="${REMARK_BACKUP_DIR}/tmp"
  kubectl cp "${REMARK_NAMESPACE}/${pod}:var/pictures" "${tmp}"
  tar -zcf "${REMARK_BACKUP_DIR}/$(date +%y%m%d)-images.tar.gz" -C "${tmp}" .
  rm -rf "${tmp}"
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

  mkdir -p "${REMARK_BACKUP_DIR}"

  if ! download_backups; then
    echo "Downloading automatic backups failed." >&2
    success=false
  fi

  if ! backup_avatars; then
    echo "Backing up avatars failed." >&2
    success=false
  fi

  if ! backup_images; then
    echo "Backing up images failed." >&2
    success=false
  fi

  if [ "${success}" = false ]; then
    exit 1
  fi

  cleanup "${REMARK_BACKUP_DIR}" 30
  echo "Success."
}

# Entrypoint
main
