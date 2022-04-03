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
  find "$1" -mtime "+${BACKUP_FILE_MAX_AGE_DAYS}" -type f -delete
}
