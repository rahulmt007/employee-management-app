# Deployment Guide

## Overview

This guide explains how to deploy the Employee Management Application using GitHub Actions, Amazon S3, AWS Systems Manager (SSM), and Amazon EC2.

The deployment process is fully automated and uses a release-based deployment strategy.

---

# Deployment Workflow

```text
Developer
    │
    ▼
Git Push
    │
    ▼
GitHub Actions
    │
    ▼
Build Deployment Artifact
    │
    ▼
Upload Artifact to Amazon S3
    │
    ▼
AWS Systems Manager (SSM)
    │
    ▼
EC2 Instances
    │
    ▼
bootstrap.sh
    │
    ▼
deploy.sh
    │
    ▼
Health Check
```

---

# Prerequisites

## AWS Infrastructure

The following AWS resources must already exist.

### Amazon EC2

- Amazon Linux 2023
- Apache HTTP Server
- PHP
- AWS CLI
- unzip
- rsync

---

### Amazon RDS

- MySQL
- Security Group allowing connections from EC2

---

### Application Load Balancer

- Listener on HTTP (Port 80)
- Target Group configured for EC2 instances

---

### Auto Scaling Group

Example:

```
Auto Scaling Group

Name

capstone-asg

Desired Capacity

2

Minimum

2

Maximum

4
```

---

### Amazon S3

Example bucket:

```
rahulmt007-employee-management-artifacts
```

Stores versioned deployment artifacts.

---

### AWS Systems Manager

Requirements:

- SSM Agent installed
- EC2 instances registered with Systems Manager
- IAM Instance Profile attached

---

# IAM Permissions

The EC2 instance profile must allow:

- AmazonSSMManagedInstanceCore
- AmazonS3ReadOnlyAccess

GitHub Actions IAM user requires:

- S3 Upload
- SSM SendCommand
- Auto Scaling Read
- EC2 Describe

---

# GitHub Secrets

Configure the following repository secrets.

| Secret | Description |
|---------|-------------|
| AWS_ACCESS_KEY_ID | AWS Access Key |
| AWS_SECRET_ACCESS_KEY | AWS Secret Key |

The workflow uses:

```
AWS_REGION = us-east-1
```

```
S3_BUCKET = rahulmt007-employee-management-artifacts
```

```
ASG_NAME = capstone-asg
```

---

# Repository Structure

```
.
├── app
│
├── scripts
│
├── docs
│
├── .github
│   └── workflows
│
└── README.md
```

---

# Deployment Scripts

| Script | Responsibility |
|----------|---------------|
| bootstrap.sh | Downloads deployment package and starts deployment |
| deploy.sh | Performs application deployment |
| backup.sh | Creates deployment backup |
| rollback.sh | Restores previous release |
| verify_deployment.sh | Runs health check |
| prune_releases.sh | Removes old releases |
| common.sh | Shared configuration |

---

# Release Directory Layout

```
/opt/employee-app

├── current
├── releases
├── backups
├── logs
└── scripts
```

Each deployment creates a unique release directory.

Example:

```
releases/

20260706-183129-7d9d366...
```

The symbolic link

```
current
```

always points to the active deployment.

---

# Deployment Steps

## Step 1

Developer pushes code.

```
git push
```

---

## Step 2

GitHub Actions

- validates repository
- builds deployment artifact
- uploads artifact to Amazon S3

---

## Step 3

GitHub Actions discovers EC2 instances inside

```
capstone-asg
```

---

## Step 4

AWS Systems Manager executes

```
bootstrap.sh
```

on every instance.

---

## Step 5

bootstrap.sh

- downloads artifact
- extracts artifact
- launches deploy.sh

---

## Step 6

deploy.sh

- creates release
- copies application
- updates current symlink
- restarts Apache
- verifies deployment
- performs rollback if needed

---

# Health Check

Deployment verification uses

```
http://localhost/healthcheck.php
```

Expected response

```
HTTP 200

OK
```

---

# Rollback

Rollback is automatic if deployment verification fails.

It can also be executed manually.

```
bash rollback.sh
```

---

# Useful Commands

Apache Status

```bash
sudo systemctl status httpd
```

Restart Apache

```bash
sudo systemctl restart httpd
```

Health Check

```bash
curl http://localhost/healthcheck.php
```

Current Release

```bash
ls -la /opt/employee-app/current
```

Release History

```bash
ls -la /opt/employee-app/releases
```

Deployment Logs

```bash
ls -la /opt/employee-app/logs
```

---

# Deployment Verification Checklist

- GitHub Actions completed successfully
- Deployment artifact uploaded to Amazon S3
- SSM command executed successfully
- Apache service running
- Health check returns HTTP 200
- Application accessible through the Application Load Balancer

---

# Version

Current deployment framework

**v1.0-ssm-cicd**