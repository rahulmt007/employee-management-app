#!/bin/bash

###############################################################################
# Remove Old Releases
###############################################################################

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

KEEP_RELEASES=5

info "Removing old releases..."

OLD_RELEASES=$(
find "${RELEASES_DIR}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    | sort \
    | head -n -"${KEEP_RELEASES}" 2>/dev/null || true
)

if [[ -z "${OLD_RELEASES}" ]]; then

    info "Nothing to prune."

    exit 0

fi

while read -r RELEASE
do

    [[ -z "$RELEASE" ]] && continue

    info "Removing ${RELEASE}"

    run rm -rf "${RELEASE}"

done <<< "${OLD_RELEASES}"

info "Release pruning complete."