# Deployment Guide

## Overview

This guide explains how the Employee Management Application is deployed to AWS using GitHub Actions, Amazon S3, AWS Systems Manager, EC2, an Auto Scaling Group, an Application Load Balancer, and Amazon RDS MySQL.

The deployment strategy is release-based. Each deployment creates a new release directory and updates the `current` symlink only after validation.

## Deployment Targets

| Item | Value |
| --- | --- |
| AWS Region | `us-east-1` |
| Auto Scaling Group | `capstone-asg` |
| S3 Artifact Bucket | `rahulmt007-employee-management-artifacts` |
| Application Name | `EmployeeManagement` |
| Runtime | Apache, PHP, PHP-FPM |
| Database | Amazon RDS MySQL |

## Workflow Triggers

The workflow runs when:

- Code is pushed to `main`
- Code is pushed to `refactor/v2-enterprise-pipeline`
- The workflow is started manually with `workflow_dispatch`

For production-style verification, use `main`.

## Required AWS Infrastructure

The following resources must exist before deployment:

- VPC and subnets
- Security groups for ALB, EC2, and RDS
- Application Load Balancer with HTTP listener on port 80
- Target group registered to the Auto Scaling Group
- Auto Scaling Group named `capstone-asg`
- Launch Template with EC2 user data from `infrastructure/userdata.sh`
- Amazon RDS MySQL database
- S3 bucket for deployment artifacts
- IAM instance profile for EC2
- IAM user or role credentials for GitHub Actions
- CloudWatch dashboard/alarm and optional SNS topic

## GitHub Secrets

Configure these repository secrets before running the deployment workflow.

| Secret | Purpose |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | AWS credential used by GitHub Actions |
| `AWS_SECRET_ACCESS_KEY` | AWS credential used by GitHub Actions |
| `DB_HOST` | RDS endpoint |
| `DB_USER` | Database username |
| `DB_PASS` | Database password |
| `DB_NAME` | Database name, for example `employeedb` |

Do not commit secrets into the repository.

## EC2 Instance Profile Permissions

The EC2 instances need permissions for:

- AWS Systems Manager managed instance registration
- Reading deployment artifacts from S3

Common managed policies used in this project:

- `AmazonSSMManagedInstanceCore`
- S3 read access, scoped to the artifact bucket where possible

## GitHub Actions Permissions

The GitHub Actions AWS identity needs permissions for:

- Uploading artifacts to S3
- Describing Auto Scaling Groups
- Describing SSM managed instances
- Sending SSM commands
- Reading SSM command invocation output

Future improvement: replace long-lived AWS keys with GitHub OIDC and an assumable IAM role.

## Deployment Flow

```text
Developer pushes to main
  |
  v
GitHub Actions starts
  |
  v
Validate repository files
  |
  v
Generate VERSION and manifest.json
  |
  v
Package app/ and scripts/ into ZIP
  |
  v
Upload artifact to GitHub Actions and S3
  |
  v
Discover InService ASG instances
  |
  v
Verify SSM PingStatus is Online
  |
  v
Send AWS-RunShellScript command
  |
  v
Download artifact on EC2
  |
  v
Run scripts/bootstrap.sh
  |
  v
Run scripts/deploy.sh
  |
  v
Verify localhost health check
```

## Release Directory Layout

```text
/opt/employee-app
|-- current -> releases/<active-release>
|-- releases/
|-- backups/
|-- logs/
`-- scripts/
```

Each release name includes a timestamp and commit SHA.

## Deployment Scripts

| Script | Responsibility |
| --- | --- |
| `bootstrap.sh` | Downloads and extracts the deployment artifact, then starts deployment |
| `deploy.sh` | Creates release, copies files, updates symlink, restarts services, verifies deployment |
| `backup.sh` | Archives the previous release before switching |
| `rollback.sh` | Repoints `current` to the previous release |
| `verify_deployment.sh` | Confirms `healthcheck.php` returns HTTP 200 |
| `prune_releases.sh` | Keeps recent releases and removes older ones |
| `common.sh` | Shared deployment paths and helper functions |

## Service Restarts

The deployment restarts:

- `php-fpm`, when available
- `httpd`

Restarting PHP-FPM is important because PHP runtime caching can otherwise keep serving stale output even when the deployed PHP file is updated.

## Manual Deployment

Use this when instances were replaced or the app shows Apache's default page.

1. Open GitHub repository.
2. Go to **Actions**.
3. Select **Employee Management Deployment**.
4. Click **Run workflow**.
5. Select branch `main`.
6. Wait for both jobs to succeed:
   - `Build Deployment Artifact`
   - `Deploy to Auto Scaling Group`
7. Open the ALB URL and hard refresh.

## Local Git Deployment Steps

```bash
git checkout main
git pull origin main
git status
git add <changed-files>
git commit -m "Describe the change"
git push origin main
```

The push to `main` starts the GitHub Actions deployment.

## Verification Checklist

After deployment:

- GitHub Actions workflow completed successfully
- Artifact uploaded to S3
- SSM command succeeded on all target instances
- ALB target group shows healthy targets
- Application loads through the ALB DNS name
- Add, search, edit, and delete employee flows work
- Footer shows `Employee Management System • Version 3.0.0`
- `http://localhost/healthcheck.php` returns `OK` on EC2

## Useful EC2 Commands

Run through SSM Session Manager or SSM Run Command.

```bash
sudo systemctl status httpd
sudo systemctl status php-fpm
```

```bash
curl http://localhost/healthcheck.php
```

```bash
ls -la /opt/employee-app/current
readlink -f /opt/employee-app/current
```

```bash
grep -n "Version" /opt/employee-app/current/index.php
```

```bash
ls -la /opt/employee-app/releases
ls -la /opt/employee-app/logs
```

## Instance Replacement Note

If EC2 instances are terminated and the Auto Scaling Group launches new ones, the new instances may initially show Apache's default page or the initial bootstrap release.

Wait until the instances are:

- `InService` in the Auto Scaling Group
- `healthy` in the target group
- `Online` in Systems Manager

Then rerun the GitHub Actions workflow on `main`.

## Version

Current documented milestone: `v3.0.0`
