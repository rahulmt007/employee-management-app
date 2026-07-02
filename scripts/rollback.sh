#!/bin/bash

source scripts/common.sh

echo_log "Rollback initiated..."

LATEST_BACKUP=$(ls -td "$BACKUP_DIR"/* | head -1)

if [ -z "$LATEST_BACKUP" ]; then

    echo_log "No backup found."

    exit 1

fi

ln -sfn "$LATEST_BACKUP" "$CURRENT_LINK"

sudo systemctl restart httpd

echo_log "Rollback completed."