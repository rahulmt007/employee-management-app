#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

KEEP_RELEASES=5

echo_log "Pruning old releases..."

cd "$RELEASES_DIR"

COUNT=$(find . -maxdepth 1 -mindepth 1 -type d | wc -l)

if [[ "$COUNT" -le "$KEEP_RELEASES" ]]; then
    echo_log "No releases need pruning."
    exit 0
fi

find . \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    | sort \
    | head -n -"${KEEP_RELEASES}" \
    | while read -r release
do
    echo_log "Removing $release"

    rm -rf "$RELEASES_DIR/${release#./}"

done

echo_log "Release pruning completed."