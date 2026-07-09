#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

APACHE_ENV_FILE="/etc/httpd/conf.d/employee-app-env.conf"

DB_HOST="${DB_HOST:?DB_HOST is not set}"
DB_USER="${DB_USER:?DB_USER is not set}"
DB_PASS="${DB_PASS:?DB_PASS is not set}"
DB_NAME="${DB_NAME:?DB_NAME is not set}"

APACHE_RESTART_REQUIRED=0

write_apache_env_config() {
    info "Configuring Apache application environment..."

    TMP_FILE="$(mktemp)"

    cat > "$TMP_FILE" <<EOF
SetEnv DB_HOST ${DB_HOST}
SetEnv DB_USER ${DB_USER}
SetEnv DB_PASS ${DB_PASS}
SetEnv DB_NAME ${DB_NAME}
EOF

    if [[ ! -f "$APACHE_ENV_FILE" ]] || ! cmp -s "$TMP_FILE" "$APACHE_ENV_FILE"; then
        run cp "$TMP_FILE" "$APACHE_ENV_FILE"
        APACHE_RESTART_REQUIRED=1
        info "Apache environment configuration updated."
    else
        info "Apache environment configuration already up to date."
    fi

    rm -f "$TMP_FILE"
}

verify_database_connection() {
    info "Verifying database connection..."

    php -r '
        $conn = new mysqli(
            getenv("DB_HOST"),
            getenv("DB_USER"),
            getenv("DB_PASS"),
            getenv("DB_NAME")
        );

        if ($conn->connect_error) {
            fwrite(STDERR, "Database connection failed\n");
            exit(1);
        }

        echo "Database connection successful\n";
        $conn->close();
    '
}

[[ -d "${ARTIFACT_DIR}" ]] || fatal "Artifact directory does not exist."
[[ -f "${ARTIFACT_DIR}/index.php" ]] || fatal "index.php not found."

write_apache_env_config

export DB_HOST DB_USER DB_PASS DB_NAME
verify_database_connection

info "Creating release directory..."
run mkdir -p "${RELEASE_DIR}"

info "Copying application..."
run rsync -a --delete "${ARTIFACT_DIR}/" "${RELEASE_DIR}/"

info "Applying permissions..."
run find "${RELEASE_DIR}" -type d -exec chmod 755 {} \;
run find "${RELEASE_DIR}" -type f -exec chmod 644 {} \;

if [[ -L "${CURRENT_LINK}" ]]; then
    info "Backing up current release..."
    bash "${SCRIPT_DIR}/backup.sh"
else
    warn "No current deployment found. Skipping backup."
fi

info "Updating current symlink..."
run ln -sfn "${RELEASE_DIR}" "${CURRENT_LINK}"

info "Validating Apache configuration..."
run apachectl configtest

info "Restarting Apache..."
run systemctl restart httpd

info "Checking Apache status..."
run systemctl is-active --quiet httpd

info "Running deployment verification..."
if ! bash "${SCRIPT_DIR}/verify_deployment.sh"; then
    error "Deployment verification failed."
    bash "${SCRIPT_DIR}/rollback.sh"
    exit 1
fi

info "Pruning old releases..."
bash "${SCRIPT_DIR}/prune_releases.sh"

info "Deployment completed successfully."
info "Release: ${RELEASE_NAME}"