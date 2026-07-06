# Troubleshooting Guide

## Overview

This document provides solutions to common issues that may occur while building, deploying, and operating the Employee Management Application.

Most of these scenarios were encountered and resolved during the development of this project.

---

# Deployment Pipeline

## GitHub Actions fails immediately

### Symptoms

- Workflow stops during repository validation.
- Build artifact is not created.

### Possible Causes

- Missing files
- Incorrect repository structure
- Invalid YAML syntax

### Resolution

Verify the repository structure.

```
.
├── app
├── scripts
├── docs
├── .github
│   └── workflows
└── README.md
```

Run:

```bash
git status
git ls-tree -r --name-only HEAD
```

---

# AWS Region Mismatch

## Symptoms

GitHub Actions reports:

```
No instances found
```

or

```
Auto Scaling Group not found
```

### Cause

GitHub Actions and AWS CLI are using different AWS Regions.

### Resolution

Verify the configured region.

```bash
aws configure get region
```

Ensure the workflow and AWS resources use the same region.

Example:

```
us-east-1
```

---

# Auto Scaling Group Discovery Failure

## Symptoms

```
Raw Output:
None
```

### Cause

Incorrect region or incorrect Auto Scaling Group name.

### Resolution

Verify the Auto Scaling Group.

```bash
aws autoscaling describe-auto-scaling-groups \
--region us-east-1 \
--auto-scaling-group-names capstone-asg
```

Confirm the EC2 instances are in the **InService** state.

---

# SSM Deployment Failure

## Symptoms

GitHub Actions stops at:

```
Wait For Deployment
```

### Cause

The SSM command failed on one or more EC2 instances.

### Resolution

Retrieve the command output.

```bash
aws ssm get-command-invocation \
--command-id <COMMAND_ID> \
--instance-id <INSTANCE_ID>
```

Review:

- StandardOutputContent
- StandardErrorContent

---

# S3 Download Failure

## Symptoms

```
Unable to download deployment artifact
```

### Possible Causes

- Incorrect bucket name
- Missing IAM permission
- Artifact not uploaded

### Resolution

Verify the artifact exists.

```bash
aws s3 ls s3://rahulmt007-employee-management-artifacts
```

Verify the EC2 instance IAM role includes S3 read permissions.

---

# bootstrap.sh Fails

## Symptoms

```
S3_BUCKET is not set
```

### Cause

Required environment variables were not exported before executing the bootstrap script.

### Resolution

Ensure the workflow exports:

```
S3_BUCKET
ARTIFACT_NAME
GITHUB_SHA
```

before running:

```bash
bash scripts/bootstrap.sh
```

---

# Apache Not Serving the Application

## Symptoms

Application returns:

```
404 Not Found
```

or

```
Forbidden
```

### Cause

Apache DocumentRoot does not match the deployment directory.

### Resolution

Verify the DocumentRoot.

```bash
grep -R "DocumentRoot" \
/etc/httpd/conf \
/etc/httpd/conf.d
```

Expected:

```
DocumentRoot "/opt/employee-app/current"
```

---

# Apache Service Failure

## Symptoms

Deployment verification fails.

### Resolution

Check Apache status.

```bash
sudo systemctl status httpd
```

Restart Apache.

```bash
sudo systemctl restart httpd
```

Review logs.

```bash
sudo journalctl -u httpd
```

---

# Health Check Failure

## Symptoms

Deployment rollback occurs automatically.

### Resolution

Verify the endpoint.

```bash
curl http://localhost/healthcheck.php
```

Expected response:

```
OK
```

---

# Deployment Path Issues

## Symptoms

Deployment succeeds but application does not update.

### Cause

Deployment directory does not match Apache configuration.

### Correct Layout

```
/opt/employee-app

├── current
├── releases
├── backups
├── logs
└── scripts
```

The symbolic link

```
current
```

must always point to the active release.

---

# Verify Current Release

```bash
ls -la /opt/employee-app/current
```

Expected:

```
current -> releases/<release-id>
```

---

# IAM Role Issues

## Symptoms

Artifact download fails.

### Resolution

Verify the EC2 IAM role includes:

- AmazonSSMManagedInstanceCore
- AmazonS3ReadOnlyAccess (or broader S3 permissions if appropriate)

For consistency, all instances in the Auto Scaling Group should use the same IAM instance profile.

---

# Useful Commands

## Apache

```bash
sudo systemctl status httpd
```

```bash
sudo systemctl restart httpd
```

---

## Health Check

```bash
curl http://localhost/healthcheck.php
```

---

## Current Release

```bash
ls -la /opt/employee-app/current
```

---

## Release History

```bash
ls -la /opt/employee-app/releases
```

---

## Deployment Logs

```bash
ls -la /opt/employee-app/logs
```

---

## AWS Systems Manager

```bash
aws ssm list-command-invocations
```

---

## Amazon S3

```bash
aws s3 ls s3://rahulmt007-employee-management-artifacts
```

---

# Lessons Learned

During this project, several important operational lessons emerged:

- Keep the AWS Region consistent across the AWS CLI, GitHub Actions, and infrastructure.
- Standardize the IAM instance profile used by all EC2 instances in the Auto Scaling Group.
- Ensure the deployment path matches Apache's configured `DocumentRoot`.
- Validate the repository structure before packaging artifacts.
- Release-based deployments with a `current` symbolic link simplify rollbacks and reduce downtime.
- AWS Systems Manager enables secure deployments without requiring SSH access.

---

# Version

Current deployment framework:

**v1.0-ssm-cicd**