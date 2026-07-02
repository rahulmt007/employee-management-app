#!/bin/bash

source scripts/common.sh

echo_log "Cleaning old releases..."

cd "$RELEASES_DIR"

ls -dt */ | tail -n +6 | xargs -r rm -rf

echo_log "Cleanup complete."