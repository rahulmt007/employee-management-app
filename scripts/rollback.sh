#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo_log "Starting rollback..."

if [[ ! -f "$BACKUP_DIR/previous_release" ]]; then
    fail "No rollback information available."
fi

PREVIOUS_RELEASE=$(cat "$BACKUP_DIR/previous_release")

if [[ ! -d "$PREVIOUS_RELEASE" ]]; then
    fail "Previous release does not exist."
fi

ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

sudo systemctl restart httpd

echo_log "Rollback completed."

bash "$SCRIPT_DIR/verify_deployment.sh"

echo_log "Rollback verified successfully."