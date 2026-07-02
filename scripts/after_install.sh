#!/bin/bash

echo "Setting permissions..."

chown -R apache:apache /var/www/html

chmod -R 755 /var/www/html

echo "Permissions updated"