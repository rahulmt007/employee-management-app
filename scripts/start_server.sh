#!/bin/bash

echo "Restarting Apache..."

systemctl restart httpd

systemctl enable httpd

echo "Apache Started"