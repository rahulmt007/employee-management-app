#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo_log "Creating deployment backup..."

if [[ -L "$CURRENT_LINK" ]]; then

    PREVIOUS_RELEASE=$(readlink -f "$CURRENT_LINK")

    echo "$PREVIOUS_RELEASE" > "$BACKUP_DIR/previous_release"

    echo_log "Previous release recorded: $PREVIOUS_RELEASE"

else

    echo_log "No existing deployment found."

fi