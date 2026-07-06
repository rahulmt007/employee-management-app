#!/bin/bash

set -Eeuo pipefail

APP_ROOT="/opt/employee-app"

RELEASES_DIR="$APP_ROOT/releases"
CURRENT_LINK="$APP_ROOT/current"
WEB_ROOT="$CURRENT_LINK"

BACKUP_DIR="$APP_ROOT/backups"
LOG_DIR="$APP_ROOT/logs"

WORKSPACE="/tmp/employee-deployment"
ARTIFACT_DIR="$WORKSPACE/extracted"

DEPLOYMENT_ID="${DEPLOYMENT_ID:-$(date +%Y%m%d-%H%M%S)}"
GIT_SHA="${GIT_SHA:-manual}"

RELEASE_NAME="${DEPLOYMENT_ID}-${GIT_SHA:0:7}"
RELEASE_DIR="$RELEASES_DIR/$RELEASE_NAME"

LOG_FILE="$LOG_DIR/deployment.log"

ensure_directory() {
    mkdir -p "$1"
}

ensure_directory "$RELEASES_DIR"
ensure_directory "$BACKUP_DIR"
ensure_directory "$LOG_DIR"
ensure_directory "$WORKSPACE"

echo_log() {
    local level="${2:-INFO}"
    echo "[$(date '+%F %T')] [$level] $1" | tee -a "$LOG_FILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

fail() {
    echo_log "$1" "ERROR"
    exit 1
}