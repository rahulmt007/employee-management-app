#!/bin/bash

APP_ROOT="/opt/employee-app"

RELEASES_DIR="$APP_ROOT/releases"
CURRENT_LINK="$APP_ROOT/current"
WEB_ROOT="$CURRENT_LINK"

BACKUP_DIR="$APP_ROOT/backups"
LOG_DIR="$APP_ROOT/logs"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SHORT_SHA=${GITHUB_SHA:-manual}
SHORT_SHA=${SHORT_SHA:0:7}

RELEASE_NAME="${TIMESTAMP}-${SHORT_SHA}"
RELEASE_DIR="$RELEASES_DIR/$RELEASE_NAME"

LOG_FILE="$LOG_DIR/deployment.log"

mkdir -p "$RELEASES_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

echo_log() {
    local level="${2:-INFO}"
    echo "[$(date '+%F %T')] [$level] $1" | tee -a "$LOG_FILE"
}