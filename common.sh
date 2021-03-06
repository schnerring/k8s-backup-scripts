#!/bin/sh

BACKUP_FILE_MAX_AGE_DAYS=30
CLICKHOUSE_BACKUP_VERSION=1.3.1

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
#   Backup file path
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

########################################
# Install clickhouse-backup into Plausible event data pod.
# Globals:
#   CLICKHOUSE_BACKUP_VERSION
#   PLAUSIBLE_EVENT_DATA_LABEL
#   PLAUSIBLE_NAMESPACE
# Arguments:
#   None
########################################
install_clickhouse_backup() {
  pod=$(get_pod_name "${PLAUSIBLE_EVENT_DATA_LABEL}" "${PLAUSIBLE_NAMESPACE}")
  # Check if clickhouse-backup has been downloaded
  if kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    wget \
      --quiet \
      --continue \
      --no-clobber \
      --output-document=/tmp/clickhouse-backup.tar.gz \
      "https://github.com/AlexAkulov/clickhouse-backup/releases/download/v${CLICKHOUSE_BACKUP_VERSION}/clickhouse-backup-linux-amd64.tar.gz" 2>/dev/null; then
    echo "Installing clickhouse-backup v${CLICKHOUSE_BACKUP_VERSION} ..."
    # Extract clickhouse-backup to /usr/local/bin
    kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
      tar -xf /tmp/clickhouse-backup.tar.gz --directory=/usr/local/bin --strip-components=3
  fi
}
