#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo_log "========== Deployment Started =========="

# Verify extracted artifact exists
if [[ ! -f "$ARTIFACT_DIR/index.php" ]]; then
    fail "Deployment artifact not found at $ARTIFACT_DIR"
fi

echo_log "Creating backup..."

bash "$SCRIPT_DIR/backup.sh"

echo_log "Creating release directory..."

mkdir -p "$RELEASE_DIR"

echo_log "Copying application files..."

rsync -a --delete \
    "$ARTIFACT_DIR"/ \
    "$RELEASE_DIR"/

echo_log "Updating current release..."

ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

echo_log "Setting permissions..."

sudo chown -R apache:apache "$RELEASE_DIR"

find "$RELEASE_DIR" -type d -exec chmod 755 {} \;

find "$RELEASE_DIR" -type f -exec chmod 644 {} \;

echo_log "Restarting Apache..."

sudo systemctl restart httpd

echo_log "Running deployment verification..."

if bash "$SCRIPT_DIR/verify_deployment.sh"
then
    echo_log "Deployment verification passed."
else
    echo_log "Deployment verification failed." "ERROR"

    bash "$SCRIPT_DIR/rollback.sh"

    fail "Rollback completed."
fi

echo_log "Pruning old releases..."

bash "$SCRIPT_DIR/prune_releases.sh"

echo_log "========== Deployment Finished =========="