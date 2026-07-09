# Troubleshooting Guide

## Overview

This guide captures issues encountered while building, deploying, and operating the AWS Employee Management Application.

The most important lesson: when the Auto Scaling Group replaces instances, the new EC2 instances need a fresh GitHub Actions deployment after bootstrap.

## Quick Checks

Start with these checks:

```bash
git status
git log --oneline -5
```

In GitHub Actions:

- Confirm the latest workflow ran on `main`
- Confirm both jobs succeeded
- Open `Deploy to Auto Scaling Group`
- Confirm every current ASG instance was listed and deployed

In AWS:

- ASG instances are `InService`
- Target group targets are `healthy`
- SSM managed instances are `Online`
- RDS status is `Available`

## GitHub Actions Fails During Validation

### Symptoms

- Workflow stops early
- Deployment artifact is not created
- Validation step reports missing files

### Common Causes

- Missing `app/` directory
- Missing `scripts/` directory
- Shell script syntax issue
- File renamed but workflow validation not updated

### Resolution

Check the repository structure:

```bash
git ls-tree -r --name-only HEAD
```

Validate scripts on a Linux environment:

```bash
bash -n scripts/bootstrap.sh
bash -n scripts/common.sh
bash -n scripts/deploy.sh
bash -n scripts/backup.sh
bash -n scripts/rollback.sh
bash -n scripts/verify_deployment.sh
bash -n scripts/prune_releases.sh
```

## No InService Instances Found

### Symptoms

GitHub Actions reports:

```text
No InService instances found in ASG.
```

### Common Causes

- Auto Scaling Group desired capacity is `0`
- Instances are still launching
- Wrong ASG name
- Wrong AWS region

### Resolution

Verify:

```bash
aws autoscaling describe-auto-scaling-groups \
  --region us-east-1 \
  --auto-scaling-group-names capstone-asg
```

Wait until instances are `InService`, then rerun the workflow.

## SSM Instance Is Not Online

### Symptoms

GitHub Actions reports:

```text
Instance <id> is not Online in SSM.
```

### Common Causes

- SSM Agent not running
- Missing IAM instance profile
- Instance has no outbound network path
- New instance is still bootstrapping

### Resolution

Check the EC2 IAM instance profile includes SSM permissions.

Expected managed policy:

```text
AmazonSSMManagedInstanceCore
```

Wait a few minutes after launch and rerun the deployment workflow.

## Apache Default Page: "It works!"

### Symptoms

The ALB URL shows:

```text
It works!
```

or the browser tab title says:

```text
It works! Apache httpd
```

### Cause

The EC2 instance is serving Apache's default page or has only completed bootstrap. The full application deployment has not been applied to that instance.

This commonly happens after manually terminating EC2 instances and letting the Auto Scaling Group launch replacements.

### Resolution

1. Wait for new instances to become `InService`.
2. Confirm they are `Online` in Systems Manager.
3. Rerun GitHub Actions workflow on `main`.
4. Hard refresh the ALB URL.

If the issue remains, verify Apache's `DocumentRoot`:

```bash
grep -R "DocumentRoot" /etc/httpd/conf /etc/httpd/conf.d
```

Expected:

```text
DocumentRoot "/opt/employee-app/current"
```

## Application Still Shows Old Version

### Symptoms

The source code and GitHub Actions deployment are updated, but the browser still shows older PHP output, such as:

```text
Employee Management System • Version 2.0
```

### Common Causes

- Browser cache
- ALB routing to an instance that missed deployment
- PHP-FPM or PHP opcode cache serving stale output

### Resolution

First hard refresh:

```text
Ctrl + F5
```

Then refresh multiple times. If the version changes between requests, compare target group instance IDs with the deployment log.

On the EC2 instance, verify the deployed file:

```bash
grep -n "Version" /opt/employee-app/current/index.php
readlink -f /opt/employee-app/current
```

Restart services:

```bash
sudo systemctl restart php-fpm
sudo systemctl restart httpd
```

The deployment script now restarts PHP-FPM when available to prevent this issue.

## S3 Artifact Download Fails

### Symptoms

Deployment logs show an artifact download failure.

### Common Causes

- Incorrect S3 bucket name
- Artifact was not uploaded
- EC2 instance role lacks S3 read permission
- Region mismatch

### Resolution

Verify artifacts:

```bash
aws s3 ls s3://rahulmt007-employee-management-artifacts
```

Check EC2 instance role permissions.

## Database Connection Failed

### Symptoms

Application shows:

```text
Database connection failed
```

### Common Causes

- Incorrect `DB_HOST`, `DB_USER`, `DB_PASS`, or `DB_NAME`
- RDS security group does not allow EC2 access
- RDS instance is stopped or unavailable
- Apache environment file was not updated

### Resolution

Confirm GitHub secrets:

```text
DB_HOST
DB_USER
DB_PASS
DB_NAME
```

Check Apache environment configuration on EC2:

```bash
sudo cat /etc/httpd/conf.d/employee-app-env.conf
```

Do not share this file publicly because it contains database credentials.

Restart services:

```bash
sudo systemctl restart php-fpm
sudo systemctl restart httpd
```

## Deployment Verification Fails

### Symptoms

Deployment rolls back automatically.

### Cause

`verify_deployment.sh` did not receive HTTP 200 from:

```text
http://localhost/healthcheck.php
```

### Resolution

Run:

```bash
curl -i http://localhost/healthcheck.php
sudo systemctl status httpd
sudo journalctl -u httpd --no-pager
```

Check the active release:

```bash
readlink -f /opt/employee-app/current
ls -la /opt/employee-app/current
```

## Rollback Problems

### Symptoms

Manual rollback fails before switching releases.

### Possible Cause

Some helper scripts source `common.sh`, which expects deployment environment variables during normal deployment.

### Resolution

Prefer the automated rollback path triggered by `deploy.sh`.

If manual rollback is needed, inspect:

```bash
ls -la /opt/employee-app/releases
readlink -f /opt/employee-app/current
```

Then carefully repoint the symlink only after identifying the correct previous release.

## Useful Commands

### Apache and PHP-FPM

```bash
sudo systemctl status httpd
sudo systemctl status php-fpm
sudo systemctl restart php-fpm
sudo systemctl restart httpd
```

### Application Release

```bash
readlink -f /opt/employee-app/current
ls -la /opt/employee-app/releases
ls -la /opt/employee-app/logs
```

### Health Check

```bash
curl -i http://localhost/healthcheck.php
```

### Version Check

```bash
grep -n "Version" /opt/employee-app/current/index.php
```

### SSM Command Output

```bash
aws ssm get-command-invocation \
  --command-id <COMMAND_ID> \
  --instance-id <INSTANCE_ID>
```

## Lessons Learned

- Keep AWS region consistent across GitHub Actions, CLI, and resources.
- Do not assume fresh ASG instances have the full app. They need the deployment workflow after bootstrap.
- Restart PHP-FPM as part of PHP deployments.
- Compare ASG instance IDs, target group IDs, and GitHub Actions target instance logs when debugging mixed behavior.
- Store screenshots and documentation before deleting AWS resources.
- Keep secrets out of screenshots and repository files.

## Version

Current documented milestone: `v3.0.0`
