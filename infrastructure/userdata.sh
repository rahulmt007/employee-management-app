#!/bin/bash
set -euxo pipefail

###############################################################################
# Employee Management - EC2 Bootstrap
#
# Purpose:
#   Prepare a newly launched EC2 instance for deployments.
#
# Responsibilities:
#   - Update OS
#   - Install Apache, PHP and required packages
#   - Configure Apache DocumentRoot
#   - Create deployment directories
#   - Create an initial healthcheck so ALB marks the instance healthy
#
# Application deployment is handled by:
# GitHub Actions -> S3 -> AWS SSM -> bootstrap.sh -> deploy.sh
###############################################################################

echo "=================================================="
echo "Employee Management EC2 Bootstrap"
echo "=================================================="

#
# Update system
#
dnf -y update

#
# Install required packages
#
dnf install -y \
    httpd \
    php \
    php-mysqlnd \
    php-fpm \
    unzip \
    rsync \
    jq

#
# Enable Apache
#
systemctl enable httpd

#
# Create deployment directories
#
mkdir -p /opt/employee-app/releases
mkdir -p /opt/employee-app/backups
mkdir -p /opt/employee-app/logs
mkdir -p /opt/employee-app/scripts

#
# Create initial release
#
mkdir -p /opt/employee-app/releases/initial

#
# Create initial ALB health check page
#
cat > /opt/employee-app/releases/initial/healthcheck.php <<'EOF'
<?php
http_response_code(200);
echo "OK";
EOF

#
# Point current -> initial
#
ln -sfn \
    /opt/employee-app/releases/initial \
    /opt/employee-app/current

#
# Permissions
#
chown -R apache:apache /opt/employee-app

#
# Backup Apache configuration
#
cp /etc/httpd/conf/httpd.conf \
   /etc/httpd/conf/httpd.conf.bak

#
# Update DocumentRoot
#
sed -i \
's#DocumentRoot "/var/www/html"#DocumentRoot "/opt/employee-app/current"#' \
/etc/httpd/conf/httpd.conf

#
# Add Directory block if missing
#
if ! grep -q '<Directory "/opt/employee-app/current">' /etc/httpd/conf/httpd.conf
then

cat <<'EOF' >> /etc/httpd/conf/httpd.conf

<Directory "/opt/employee-app/current">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

EOF

fi

#
# Validate Apache configuration
#
apachectl configtest

#
# Start Apache
#
systemctl restart httpd

echo "=================================================="
echo "Bootstrap completed successfully"
echo "=================================================="