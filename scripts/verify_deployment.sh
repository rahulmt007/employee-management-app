#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo_log "Performing deployment verification..."

HTTP_CODE=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    http://localhost/healthcheck.php)

if [[ "$HTTP_CODE" != "200" ]]; then
    fail "Health check returned HTTP $HTTP_CODE"
fi

BODY=$(curl --silent http://localhost/healthcheck.php)

if [[ "$BODY" != "OK" ]]; then
    fail "Unexpected health check response: $BODY"
fi

echo_log "Health check passed."