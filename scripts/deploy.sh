#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

: "${S3_BUCKET:?S3_BUCKET is not set}"
: "${ARTIFACT_NAME:?ARTIFACT_NAME is not set}"

ARTIFACT_PATH="/tmp/${ARTIFACT_NAME}"

echo_log "========== Deployment Started =========="

PREVIOUS_RELEASE=$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)

echo_log "Creating release directory: $RELEASE_NAME"

mkdir -p "$RELEASE_DIR"

echo_log "Downloading artifact from S3"

aws s3 cp \
"s3://${S3_BUCKET}/${ARTIFACT_NAME}" \
"$ARTIFACT_PATH"

echo_log "Extracting artifact"

unzip -oq "$ARTIFACT_PATH" -d "$RELEASE_DIR"

if [ ! -f "$RELEASE_DIR/index.php" ]; then
    echo_log "index.php not found in release." "ERROR"
    exit 1
fi

echo_log "Updating current release"

ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

echo_log "Setting permissions"

sudo chown -R apache:apache "$RELEASE_DIR"

find "$RELEASE_DIR" -type d -exec chmod 755 {} \;
find "$RELEASE_DIR" -type f -exec chmod 644 {} \;

echo_log "Restarting Apache"

sudo systemctl restart httpd

echo_log "Running health check"

if bash "$SCRIPT_DIR/verify_deployment.sh"
then
    echo_log "Deployment successful."
else

    echo_log "Health check failed." "ERROR"

    if [ -n "$PREVIOUS_RELEASE" ]; then

        echo_log "Rolling back to previous release"

        ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

        sudo systemctl restart httpd

    fi

    exit 1

fi

rm -f "$ARTIFACT_PATH"

bash "$SCRIPT_DIR/prune_releases.sh"

echo_log "========== Deployment Finished =========="