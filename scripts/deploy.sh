#!/bin/bash

###############################################################################
# Employee Management Deployment Framework v2
#
# Deploy Application
###############################################################################

set -Eeuo pipefail

###############################################################################
# Load Common Functions
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

###############################################################################
# Validate Deployment Input
###############################################################################

[[ -d "${ARTIFACT_DIR}" ]] || fatal "Artifact directory does not exist."

[[ -f "${ARTIFACT_DIR}/index.php" ]] || fatal "index.php not found."

###############################################################################
# Begin Deployment
###############################################################################

info "Creating release directory..."

run mkdir -p "${RELEASE_DIR}"

###############################################################################
# Copy Application
###############################################################################

info "Copying application..."

run rsync \
    -a \
    --delete \
    "${ARTIFACT_DIR}/" \
    "${RELEASE_DIR}/"

###############################################################################
# Permissions
###############################################################################

info "Applying permissions..."

run find "${RELEASE_DIR}" -type d -exec chmod 755 {} \;

run find "${RELEASE_DIR}" -type f -exec chmod 644 {} \;

run chmod +x "${SCRIPT_DIR}"/*.sh

###############################################################################
# Backup Current Release
###############################################################################

if [[ -L "${CURRENT_LINK}" ]]; then

    info "Backing up current release..."

    bash "${SCRIPT_DIR}/backup.sh"

else

    warn "No current deployment found. Skipping backup."

fi

###############################################################################
# Switch Current Release
###############################################################################

info "Updating current symlink..."

run ln -sfn "${RELEASE_DIR}" "${CURRENT_LINK}"

###############################################################################
# Apache Restart
###############################################################################

info "Restarting Apache..."

run systemctl restart httpd

###############################################################################
# Apache Status
###############################################################################

run systemctl is-active --quiet httpd || {

    error "Apache failed to start."

    bash "${SCRIPT_DIR}/rollback.sh"

    exit 1
}

###############################################################################
# Verify Deployment
###############################################################################

info "Running deployment verification..."

if ! bash "${SCRIPT_DIR}/verify_deployment.sh"
then

    error "Deployment verification failed."

    bash "${SCRIPT_DIR}/rollback.sh"

    exit 1

fi

###############################################################################
# Cleanup Old Releases
###############################################################################

info "Pruning old releases..."

bash "${SCRIPT_DIR}/prune_releases.sh"

###############################################################################
# Success
###############################################################################

info "==============================================="
info "Deployment completed successfully."
info "Release : ${RELEASE_NAME}"
info "==============================================="