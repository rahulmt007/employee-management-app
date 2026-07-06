#!/bin/bash

###############################################################################
# Employee Management Deployment Framework v2
#
# Common configuration and utility functions
###############################################################################

set -Eeuo pipefail

###############################################################################
# Application Information
###############################################################################

APP_NAME="employee-app"

###############################################################################
# Deployment Paths
###############################################################################

DEPLOY_ROOT="/opt/${APP_NAME}"

RELEASES_DIR="${DEPLOY_ROOT}/releases"

CURRENT_LINK="${DEPLOY_ROOT}/current"

BACKUP_DIR="${DEPLOY_ROOT}/backups"

LOG_DIR="${DEPLOY_ROOT}/logs"

###############################################################################
# Deployment Inputs
###############################################################################

: "${ARTIFACT_DIR:?ARTIFACT_DIR is not set}"

###############################################################################
# Release Information
###############################################################################

DEPLOYMENT_ID="${GITHUB_SHA:-manual}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

RELEASE_NAME="${TIMESTAMP}-${DEPLOYMENT_ID}"

RELEASE_DIR="${RELEASES_DIR}/${RELEASE_NAME}"

###############################################################################
# Logging
###############################################################################

mkdir -p "$LOG_DIR"

LOG_FILE="${LOG_DIR}/deploy-${TIMESTAMP}.log"

log() {

    local LEVEL="$1"
    shift

    local MESSAGE="$*"

    printf "[%s] %-5s %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$LEVEL" \
        "$MESSAGE" | tee -a "$LOG_FILE"
}

info() {

    log INFO "$@"
}

warn() {

    log WARN "$@"
}

error() {

    log ERROR "$@"
}

fatal() {

    error "$@"
    exit 1
}

###############################################################################
# Execute Command
###############################################################################

run() {

    info "$*"

    "$@"
}

###############################################################################
# Validation
###############################################################################

require_command() {

    command -v "$1" >/dev/null 2>&1 || \
        fatal "Required command not found: $1"
}

###############################################################################
# Ensure Required Directories Exist
###############################################################################

mkdir -p "$DEPLOY_ROOT"
mkdir -p "$RELEASES_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

###############################################################################
# Validate Required Tools
###############################################################################

require_command rsync
require_command find
require_command ln
require_command chmod
require_command chown
require_command systemctl

###############################################################################
# Banner
###############################################################################

info "==============================================="
info "Employee Management Deployment Framework"
info "Release : $RELEASE_NAME"
info "Artifact: $ARTIFACT_DIR"
info "==============================================="