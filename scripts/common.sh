#!/bin/bash

set -e

APP_NAME="employee-management-app"

BASE_DIR="/opt/employee-app"

RELEASES_DIR="$BASE_DIR/releases"

CURRENT_LINK="$BASE_DIR/current"

BACKUP_DIR="$BASE_DIR/backups"

LOG_DIR="$BASE_DIR/logs"

WEB_ROOT="/var/www/html"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

RELEASE_DIR="$RELEASES_DIR/$TIMESTAMP"

LOG_FILE="$LOG_DIR/deployment.log"

echo_log () {
    echo "$(date '+%F %T') - $1" | tee -a "$LOG_FILE"
}