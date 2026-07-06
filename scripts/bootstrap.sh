#!/bin/bash

###############################################################################
# Employee Management Deployment Framework v2
#
# Bootstrap Script
#
# Responsibilities:
#   1. Validate required environment variables
#   2. Download deployment artifact from S3
#   3. Extract deployment package
#   4. Export deployment variables
#   5. Execute deploy.sh
#   6. Cleanup temporary workspace
###############################################################################

set -Eeuo pipefail

###############################################################################
# Required Environment Variables
###############################################################################

: "${S3_BUCKET:?S3_BUCKET is not set}"
: "${ARTIFACT_NAME:?ARTIFACT_NAME is not set}"

###############################################################################
# Paths
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORK_DIR="$(mktemp -d /tmp/employee-management-XXXXXX)"

ZIP_FILE="${WORK_DIR}/deployment.zip"

###############################################################################
# Cleanup
###############################################################################

cleanup() {

    echo ""
    echo "Cleaning temporary workspace..."

    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

###############################################################################
# Banner
###############################################################################

echo "======================================================"
echo "Employee Management Deployment Bootstrap"
echo "======================================================"

echo "S3 Bucket      : ${S3_BUCKET}"
echo "Artifact       : ${ARTIFACT_NAME}"
echo "Workspace      : ${WORK_DIR}"
echo "Commit         : ${GITHUB_SHA:-manual}"

###############################################################################
# Verify Required Tools
###############################################################################

command -v aws >/dev/null || {

    echo "ERROR: aws CLI not installed."

    exit 1
}

command -v unzip >/dev/null || {

    echo "ERROR: unzip not installed."

    exit 1
}

###############################################################################
# Download Artifact
###############################################################################

echo ""
echo "Downloading deployment artifact..."

aws s3 cp \
    "s3://${S3_BUCKET}/${ARTIFACT_NAME}" \
    "${ZIP_FILE}"

###############################################################################
# Validate Download
###############################################################################

[[ -f "${ZIP_FILE}" ]] || {

    echo "ERROR: deployment artifact download failed."

    exit 1
}

###############################################################################
# Extract Artifact
###############################################################################

echo ""
echo "Extracting deployment artifact..."

unzip -oq "${ZIP_FILE}" -d "${WORK_DIR}"

###############################################################################
# Validate Package Structure
###############################################################################

echo ""
echo "Validating deployment package..."

[[ -d "${WORK_DIR}/app" ]] || {

    echo "ERROR: app directory missing."

    exit 1
}

[[ -d "${WORK_DIR}/scripts" ]] || {

    echo "ERROR: scripts directory missing."

    exit 1
}

[[ -f "${WORK_DIR}/scripts/deploy.sh" ]] || {

    echo "ERROR: deploy.sh missing."

    exit 1
}

###############################################################################
# Make Scripts Executable
###############################################################################

chmod +x "${WORK_DIR}/scripts/"*.sh

###############################################################################
# Export Environment
###############################################################################

export ARTIFACT_DIR="${WORK_DIR}/app"

export SCRIPT_DIR="${WORK_DIR}/scripts"

export GITHUB_SHA="${GITHUB_SHA:-manual}"

###############################################################################
# Execute Deployment
###############################################################################

echo ""
echo "Starting deployment..."

bash "${WORK_DIR}/scripts/deploy.sh"

STATUS=$?

###############################################################################
# Result
###############################################################################

echo ""

if [[ ${STATUS} -eq 0 ]]; then

    echo "======================================================"
    echo "Deployment completed successfully."
    echo "======================================================"

else

    echo "======================================================"
    echo "Deployment failed."
    echo "======================================================"

fi

exit "${STATUS}"