#!/bin/sh

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
