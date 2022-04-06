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
