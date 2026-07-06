#!/bin/bash

###############################################################################
# Verify Deployment
###############################################################################

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

URL="http://localhost/healthcheck.php"

info "Running deployment verification..."

HTTP_CODE=$(
curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    "${URL}"
)

if [[ "${HTTP_CODE}" != "200" ]]; then

    error "Health check failed."

    error "HTTP Status: ${HTTP_CODE}"

    exit 1

fi

info "Health check passed."

exit 0