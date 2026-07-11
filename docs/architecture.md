# System Architecture

## Overview

The Employee Management Application is a PHP and MySQL web application deployed on AWS with a release-based deployment model.

The architecture demonstrates:

- Load-balanced web application hosting
- Auto Scaling instance replacement
- RDS-backed persistent data
- GitHub Actions CI/CD
- S3 deployment artifacts
- AWS Systems Manager deployments without SSH
- CloudWatch monitoring and alerting

## High-Level Architecture

```text
Developer
  |
  v
GitHub Repository
  |
  v
GitHub Actions Workflow
  |
  +--> Build ZIP artifact
  |
  +--> Upload artifact to S3
  |
  +--> Discover ASG instances
  |
  +--> Send SSM deployment command
          |
          v
  Auto Scaling Group: capstone-asg
          |
          +-----------------------+
          |                       |
          v                       v
   EC2 Instance             EC2 Instance
   Apache + PHP             Apache + PHP
   PHP-FPM                  PHP-FPM
          |                       |
          +-----------+-----------+
                      |
                      v
          Application Load Balancer
                      |
                      v
                   End Users
                      |
                      v
                Amazon RDS MySQL
```

## Runtime Components

| Component | Role |
| --- | --- |
| Apache HTTP Server | Serves the PHP application through the ALB |
| PHP / PHP-FPM | Runs the application code |
| MySQL client extension | Connects PHP to Amazon RDS MySQL |
| `/opt/employee-app/current` | Active application release symlink |
| `/opt/employee-app/releases` | Historical application releases |
| `/opt/employee-app/logs` | Deployment logs |

## AWS Services

| Service | Purpose |
| --- | --- |
| Amazon EC2 | Runs Apache, PHP, and deployment scripts |
| Auto Scaling Group | Maintains desired capacity and replaces instances |
| Application Load Balancer | Routes HTTP traffic to healthy instances |
| Amazon RDS MySQL | Stores employee records |
| Amazon S3 | Stores generated deployment ZIP artifacts |
| AWS Systems Manager | Executes deployment commands on EC2 instances |
| IAM | Grants GitHub Actions and EC2 permissions |
| CloudWatch | Provides dashboards, alarms, and operational visibility |
| SNS | Sends alarm notifications |

## Deployment Architecture

```text
Push to main or manual workflow run
  |
  v
GitHub Actions
  |
  v
Create VERSION and manifest.json
  |
  v
Package app/ and scripts/
  |
  v
Upload artifact to S3
  |
  v
Find InService ASG instances
  |
  v
Confirm SSM Online status
  |
  v
Run deployment command through SSM
  |
  v
bootstrap.sh
  |
  v
deploy.sh
  |
  v
Create release directory
  |
  v
Update current symlink
  |
  v
Restart PHP-FPM and Apache
  |
  v
Verify healthcheck.php
```

## Release Layout

Each deployment creates a unique release directory.

```text
/opt/employee-app/
|-- current -> /opt/employee-app/releases/<release-id>
|-- releases/
|   |-- 20260709-172500-22258c7
|   |-- 20260709-170100-8facd18
|   `-- initial
|-- backups/
|-- logs/
`-- scripts/
```

The `current` symlink is the active version served by Apache.

## Bootstrap vs Deployment

Fresh Auto Scaling instances run `infrastructure/userdata.sh`.

The bootstrap script:

- Installs Apache, PHP, PHP-FPM, `rsync`, `unzip`, and `jq`
- Creates `/opt/employee-app`
- Creates an initial health check release
- Points Apache `DocumentRoot` to `/opt/employee-app/current`
- Starts Apache

The bootstrap does **not** deploy the full application. The GitHub Actions workflow must run after instances are available in the ASG and online in SSM.

## Health Checks

The deployment verification endpoint is:

```text
http://localhost/healthcheck.php
```

A deployment is considered successful only when this endpoint returns `HTTP 200`.

## Security Notes

- Deployments are performed through AWS Systems Manager rather than SSH.
- EC2 instances need SSM and S3 permissions through an IAM instance profile.
- GitHub Actions currently uses AWS repository secrets.
- Database credentials are injected into Apache environment configuration during deployment.
- A future improvement is replacing long-lived AWS access keys with GitHub OIDC and using AWS Secrets Manager or SSM Parameter Store for database credentials.

## Scaling and Replacement Behavior

The Auto Scaling Group can replace EC2 instances automatically. When that happens:

1. The new instance runs EC2 user data.
2. Apache may initially show the default page or only the initial health check release.
3. The GitHub Actions deployment must run again once the instance is `InService` and `Online` in SSM.
4. The new instance receives the same release-based application deployment.

## Monitoring

The project includes screenshots and configuration evidence for:

- CloudWatch dashboard
- CPU utilization alarm
- SNS notification path
- ALB and ASG health state

## Current Milestone

The documented application milestone is `v3.2.0`, which includes:

- Session-based admin login
- MySQL-backed PHP session storage for ALB and Auto Scaling compatibility
- Add employee
- View employee directory
- Search employee
- Edit employee
- Delete employee
- Release-based AWS deployment
- PHP-FPM restart during deployment to prevent stale PHP output
