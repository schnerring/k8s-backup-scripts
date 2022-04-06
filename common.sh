#!/bin/sh

BACKUP_FILE_MAX_AGE_DAYS=30

##################################################
# Cleanup files older than BACKUP_FILE_MAX_AGE_DAYS days.
# from BACKUP_DIR
# Globals:
#   BACKUP_FILE_MAX_AGE_DAYS
# Arguments:
#   Directory to clean
##################################################
cleanup() {
  echo "Cleaning up backups older than ${BACKUP_FILE_MAX_AGE_DAYS} days in $1 ..."
  find "$1" -mtime "+${BACKUP_FILE_MAX_AGE_DAYS}" -type f -delete
}

########################################
# Prompts for user confirmation.
# Globals:
#   None
# Arguments:
#   Backup file path.
########################################
confirm() {
  printf 'THE BACKUP %s WILL BE RESTORED!\n' "$1"
  printf 'Really continue? (y/n) '
  read -r answer

  printf '%s' "${answer}" | grep -q "^[Yy]$" || exit 1
}

########################################
# Get pod name without prefix via label and namespace.
# See also: https://stackoverflow.com/a/47453572
# Globals:
#   None
# Arguments:
#   Label
#   Namespace
########################################
get_pod_name() {
  label=$1
  namespace=$2
  pod=$(kubectl get pod -l "${label}" -n "${namespace}" -o jsonpath="{.items[0].metadata.name}")
  printf '%s' "${pod}"
}
