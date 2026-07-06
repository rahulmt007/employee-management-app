# System Architecture

## Overview

The Employee Management Application is deployed on Amazon Web Services (AWS) using a modern release-based deployment strategy with GitHub Actions and AWS Systems Manager (SSM).

The architecture is designed to provide:

- Automated deployments
- Repeatable releases
- Zero manual file transfers
- Easy rollback capability
- High availability through Auto Scaling
- Centralized artifact management

---

# High-Level Architecture

```text
                        Developer
                            │
                            ▼
                  GitHub Repository
                            │
                            ▼
                  GitHub Actions CI/CD
                            │
                            ▼
             Build Deployment Artifact
                            │
                            ▼
                    Amazon S3 Bucket
                            │
                            ▼
               AWS Systems Manager (SSM)
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
      EC2 Instance                    EC2 Instance
      Apache + PHP                    Apache + PHP
            │                               │
            └───────────────┬───────────────┘
                            ▼
               Application Load Balancer
                            │
                            ▼
                         End Users
                            │
                            ▼
                    Amazon RDS MySQL
```

---

# AWS Services Used

| Service | Purpose |
|----------|---------|
| Amazon EC2 | Hosts the PHP application |
| Auto Scaling Group | Provides high availability and scaling |
| Application Load Balancer | Distributes incoming traffic |
| Amazon RDS MySQL | Stores employee data |
| Amazon S3 | Stores deployment artifacts |
| AWS Systems Manager | Executes deployments remotely |
| GitHub Actions | Continuous Integration and Deployment |
| Amazon CloudWatch | Monitoring and alarms |
| Amazon SNS | Notifications |

---

# Deployment Architecture

The deployment process is fully automated.

```text
Git Push
    │
    ▼
GitHub Actions
    │
    ▼
Build Deployment Package
    │
    ▼
Upload Artifact to S3
    │
    ▼
Discover Auto Scaling Group Instances
    │
    ▼
AWS Systems Manager
    │
    ▼
Download Artifact
    │
    ▼
bootstrap.sh
    │
    ▼
deploy.sh
    │
    ▼
Create Release
    │
    ▼
Update current Symlink
    │
    ▼
Restart Apache
    │
    ▼
Health Check
```

---

# Release-Based Deployment

Each deployment creates a unique release directory.

Example:

```text
/opt/employee-app/

├── current
├── releases
│   ├── 20260706-183129-7d9d366...
│   ├── 20260705-164012-5a13f6d...
│   └── ...
├── backups
├── logs
└── scripts
```

The `current` symbolic link always points to the active release.

This approach provides:

- Zero-copy deployments
- Fast rollback
- Release history
- Easier troubleshooting

---

# Deployment Components

## bootstrap.sh

Responsible for:

- Downloading the deployment artifact from Amazon S3
- Extracting the deployment package
- Preparing the deployment environment
- Invoking `deploy.sh`

---

## deploy.sh

Responsible for:

- Creating a new release directory
- Copying application files
- Backing up the current release
- Updating the `current` symlink
- Restarting Apache
- Verifying deployment
- Rolling back if verification fails
- Pruning older releases

---

## verify_deployment.sh

Performs a health check against:

```text
http://localhost/healthcheck.php
```

A deployment is considered successful only if the endpoint returns **HTTP 200**.

---

# Security Considerations

The solution avoids direct SSH-based deployments.

Deployments are performed using AWS Systems Manager, which provides:

- IAM-based authentication
- Encrypted communication
- Audit logging
- No inbound SSH requirement for deployment

Deployment artifacts are stored in Amazon S3 and accessed through IAM roles attached to the EC2 instances.

---

# Monitoring

The environment includes:

- Amazon CloudWatch Dashboard
- CPU Utilization metrics
- CloudWatch Alarm
- Amazon SNS notifications

---

# Scalability

The application runs inside an Auto Scaling Group.

Benefits include:

- Automatic instance replacement
- Horizontal scaling
- High availability
- Rolling deployments across multiple instances

---

# Future Improvements

Potential enhancements include:

- HTTPS with AWS Certificate Manager
- Route 53 DNS
- Blue/Green deployments
- Infrastructure as Code with Terraform
- Docker containerization
- Amazon ECS or Amazon EKS migration