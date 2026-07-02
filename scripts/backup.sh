#!/bin/bash

source scripts/common.sh

echo_log "Starting backup..."

mkdir -p "$BACKUP_DIR"

if [ -L "$CURRENT_LINK" ]; then

    CURRENT_RELEASE=$(readlink -f "$CURRENT_LINK")

    BACKUP_NAME=$(basename "$CURRENT_RELEASE")

    cp -R "$CURRENT_RELEASE" "$BACKUP_DIR/$BACKUP_NAME"

    echo_log "Backup completed."

else

    echo_log "No previous deployment found."

fi