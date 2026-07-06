#!/bin/bash

###############################################################################
# Backup Current Deployment
###############################################################################

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

if [[ ! -L "${CURRENT_LINK}" ]]; then
    warn "No current deployment to backup."
    exit 0
fi

CURRENT_RELEASE="$(readlink -f "${CURRENT_LINK}")"

BACKUP_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.tar.gz"

info "Creating backup..."

run tar \
    -czf "${BACKUP_FILE}" \
    -C "$(dirname "${CURRENT_RELEASE}")" \
    "$(basename "${CURRENT_RELEASE}")"

info "Backup created"

info "${BACKUP_FILE}"