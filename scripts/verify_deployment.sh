#!/bin/bash

source scripts/common.sh

echo_log "Running Health Check..."

STATUS=$(curl -s http://localhost/healthcheck.php)

if [[ "$STATUS" == "OK" ]]; then

    echo_log "Health Check Passed"

    exit 0

fi

echo_log "Health Check Failed"

exit 1