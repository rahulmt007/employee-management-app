#!/bin/bash

###############################################################################
# Rollback Deployment
###############################################################################

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

info "Starting rollback..."

PREVIOUS_RELEASE=$(
find "${RELEASES_DIR}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    | sort \
    | tail -2 \
    | head -1
)

if [[ -z "${PREVIOUS_RELEASE}" ]]; then

    fatal "No previous release available."

fi

info "Rolling back to"

info "${PREVIOUS_RELEASE}"

run ln -sfn "${PREVIOUS_RELEASE}" "${CURRENT_LINK}"

run systemctl restart httpd

run systemctl is-active --quiet httpd

info "Rollback completed successfully."