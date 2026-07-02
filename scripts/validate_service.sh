#!/bin/bash

curl -f http://localhost/healthcheck.php

if [ $? -eq 0 ]
then
    echo "Application Healthy"
else
    echo "Application Failed"
    exit 1
fi