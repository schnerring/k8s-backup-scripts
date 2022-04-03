#!/bin/sh

# TODO
# See https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh
. "$(dirname "$0")/cleanup.sh"

##################################################
# Backup Plausible Clickhouse event database.
# Globals:
#   PLAUSIBLE_EVENT_DATA_POD_LABEL
#   PLAUSIBLE_NAMESPACE
#   PLAUSIBLE_BACKUP_DIR
#   CLICKHOUSE_BACKUP_VERSION
# Arguments:
#   None
##################################################
backup_plausible() {
  mkdir -p "${PLAUSIBLE_BACKUP_DIR}"
  pod=$(kubectl get pod -l "${PLAUSIBLE_EVENT_DATA_POD_LABEL}" -n "${PLAUSIBLE_NAMESPACE}" -o jsonpath="{.items[0].metadata.name}")

  # Check if clickhouse-backup was already downloaded
  if kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    wget \
      --quiet \
      --continue \
      --no-clobber \
      --output-document=/tmp/clickhouse-backup.tar.gz \
      "https://github.com/AlexAkulov/clickhouse-backup/releases/download/v${CLICKHOUSE_BACKUP_VERSION}/clickhouse-backup-linux-amd64.tar.gz" 2> /dev/null; then

    # Extract clickhouse-backup to /tmp
    kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
      tar -zxvf /tmp/clickhouse-backup.tar.gz --directory=/tmp --strip-components=3
  fi

  backup_name=clickhouse-backup_$(date +%y%m%d)

  # Create backup in pod
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    /tmp/clickhouse-backup create "${backup_name}"

  # Download backup from pod
  tmp="${PLAUSIBLE_BACKUP_DIR}/tmp"
  kubectl cp "${PLAUSIBLE_NAMESPACE}/${pod}:/var/lib/clickhouse/backup/${backup_name}" "${tmp}"
  tar -zcvf "${PLAUSIBLE_BACKUP_DIR}/${backup_name}.tar.gz" "${tmp}"
  rm -rf "${tmp}"

  # Delete backup in pod
  kubectl exec -i -n "${PLAUSIBLE_NAMESPACE}" "$pod" -- \
    /tmp/clickhouse-backup delete local "${backup_name}"
}

##################################################
# Main function of script.
# Globals:
#   PLAUSIBLE_BACKUP_DIR
# Arguments:
#   None
##################################################
main() {
  backup_plausible || exit 1
  cleanup "${PLAUSIBLE_BACKUP_DIR}" || exit 1
}

# Entrypoint
main
