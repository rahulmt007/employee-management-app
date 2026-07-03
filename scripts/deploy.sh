#!/bin/bash

set -e

source scripts/common.sh

echo_log "========== Deployment Started =========="

# Required environment variables
: "${S3_BUCKET:?S3_BUCKET is not set}"
: "${ARTIFACT_NAME:?ARTIFACT_NAME is not set}"

mkdir -p "$RELEASE_DIR"

echo_log "Downloading artifact..."

aws s3 cp \
"s3://${S3_BUCKET}/${ARTIFACT_NAME}" \
"/tmp/${ARTIFACT_NAME}"

echo_log "Extracting artifact..."

unzip -oq "/tmp/${ARTIFACT_NAME}" -d "$RELEASE_DIR"

if [ ! -f "$RELEASE_DIR/index.php" ]; then
    echo_log "Deployment failed: index.php not found."
    exit 1
fi

echo_log "Creating backup..."

bash scripts/backup.sh

echo_log "Deploying application..."

sudo rsync -av --delete \
"$RELEASE_DIR"/ \
/var/www/html/

sudo chown -R apache:apache /var/www/html

sudo find /var/www/html -type d -exec chmod 755 {} \;

sudo find /var/www/html -type f -exec chmod 644 {} \;

echo_log "Restarting Apache..."

sudo systemctl restart httpd

echo_log "Running health check..."

if bash scripts/healthcheck.sh
then
    echo_log "Deployment successful."
else
    echo_log "Deployment failed. Rolling back..."
    bash scripts/rollback.sh
    exit 1
fi

bash scripts/cleanup.sh

echo_log "========== Deployment Finished =========="