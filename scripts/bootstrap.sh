#!/bin/bash

set -Eeuo pipefail

###############################################################################
# Employee Management Deployment Bootstrap
#
# Responsibilities
#   • Download deployment package from S3
#   • Extract deployment package
#   • Export deployment environment
#   • Execute deploy.sh
#   • Cleanup temporary files
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Validate environment
###############################################################################

: "${S3_BUCKET:?S3_BUCKET is not set}"
: "${ARTIFACT_NAME:?ARTIFACT_NAME is not set}"

GITHUB_SHA="${GITHUB_SHA:-manual}"

###############################################################################
# Create temporary workspace
###############################################################################

WORK_DIR="$(mktemp -d /tmp/employee-management-XXXXXX)"

PACKAGE_PATH="$WORK_DIR/$ARTIFACT_NAME"

cleanup() {
    echo ""
    echo "Cleaning temporary files..."
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

###############################################################################
# Banner
###############################################################################

echo "=================================================="
echo " Employee Management Deployment Bootstrap"
echo "=================================================="

echo "S3 Bucket     : $S3_BUCKET"
echo "Artifact      : $ARTIFACT_NAME"
echo "Commit        : $GITHUB_SHA"

###############################################################################
# Verify prerequisites
###############################################################################

echo ""
echo "Checking prerequisites..."

command -v aws >/dev/null || {
    echo "ERROR: AWS CLI not installed."
    exit 1
}

command -v unzip >/dev/null || {
    echo "ERROR: unzip not installed."
    exit 1
}

###############################################################################
# Download deployment package
###############################################################################

echo ""
echo "Downloading deployment package..."

aws s3 cp \
    "s3://$S3_BUCKET/$ARTIFACT_NAME" \
    "$PACKAGE_PATH"

###############################################################################
# Verify download
###############################################################################

if [[ ! -f "$PACKAGE_PATH" ]]; then
    echo "ERROR: Deployment package download failed."
    exit 1
fi

###############################################################################
# Extract package
###############################################################################

echo ""
echo "Extracting deployment package..."

unzip -oq "$PACKAGE_PATH" -d "$WORK_DIR"

###############################################################################
# Validate extracted contents
###############################################################################

echo ""
echo "Validating deployment package..."

[[ -d "$WORK_DIR/app" ]] || {
    echo "ERROR: app directory missing."
    exit 1
}

[[ -d "$WORK_DIR/scripts" ]] || {
    echo "ERROR: scripts directory missing."
    exit 1
}

[[ -f "$WORK_DIR/scripts/deploy.sh" ]] || {
    echo "ERROR: deploy.sh missing."
    exit 1
}

###############################################################################
# Export deployment environment
###############################################################################

export ARTIFACT_DIR="$WORK_DIR/app"

export SCRIPT_DIR="$WORK_DIR/scripts"

export GITHUB_SHA

###############################################################################
# Execute deployment
###############################################################################

echo ""
echo "Executing deployment..."

chmod +x "$WORK_DIR/scripts/"*.sh

bash "$WORK_DIR/scripts/deploy.sh"

STATUS=$?

###############################################################################
# Finish
###############################################################################

echo ""

if [[ $STATUS -eq 0 ]]; then
    echo "=================================================="
    echo " Deployment completed successfully"
    echo "=================================================="
else
    echo "=================================================="
    echo " Deployment failed"
    echo "=================================================="
fi

exit "$STATUS"