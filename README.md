# AWS Employee Management Application

## Project Overview

The **AWS Employee Management Application** is a PHP-based web application deployed on AWS using a fully automated CI/CD pipeline.

The project demonstrates modern deployment practices including:

- GitHub Actions for Continuous Integration and Continuous Deployment (CI/CD)
- Amazon S3 for deployment artifact storage
- AWS Systems Manager (SSM) for remote deployments
- Release-based deployments with automatic rollback support
- Amazon EC2 Auto Scaling Group
- Application Load Balancer
- Amazon RDS MySQL
- Amazon CloudWatch monitoring

---

# Project Architecture

```
Developer
    │
    ▼
GitHub Repository
    │
    ▼
GitHub Actions
    │
    ▼
Build Deployment Artifact
    │
    ▼
Amazon S3
    │
    ▼
AWS Systems Manager (SSM)
    │
    ▼
Auto Scaling Group
 ┌─────────────────────┐
 │     EC2 Instance    │
 │   Apache + PHP      │
 └─────────────────────┘
 ┌─────────────────────┐
 │     EC2 Instance    │
 │   Apache + PHP      │
 └─────────────────────┘
          │
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

# Technology Stack

| Component | Technology |
|----------|------------|
| Programming Language | PHP |
| Web Server | Apache HTTP Server |
| Database | Amazon RDS MySQL |
| Compute | Amazon EC2 |
| Scaling | Auto Scaling Group |
| Load Balancer | Application Load Balancer |
| CI/CD | GitHub Actions |
| Deployment | AWS Systems Manager (SSM) |
| Artifact Repository | Amazon S3 |
| Monitoring | Amazon CloudWatch |
| Notifications | Amazon SNS |
| Version Control | Git & GitHub |

---

# Application Features

- Add Employee
- View Employees
- Search Employees
- Health Check Endpoint
- Amazon RDS Integration

---

# CI/CD Pipeline

The deployment pipeline performs the following steps automatically whenever code is pushed.

1. Checkout source code
2. Validate repository structure
3. Generate deployment artifact
4. Upload artifact to GitHub Actions
5. Upload artifact to Amazon S3
6. Discover EC2 instances in the Auto Scaling Group
7. Deploy using AWS Systems Manager
8. Create a new application release
9. Update the current symlink
10. Restart Apache
11. Verify deployment
12. Complete deployment

---

# Release-Based Deployment

Application deployments use a release-based directory structure.

```
/opt/employee-app

├── current
├── releases
├── backups
├── logs
└── scripts
```

Each deployment creates a new release directory and updates the `current` symbolic link after successful verification.

---

# Monitoring

The project includes:

- CloudWatch Dashboard
- CPU Utilization Monitoring
- CloudWatch Alarm
- Amazon SNS Notifications

---

# Repository Structure

```
.
├── app
│   ├── assets
│   ├── sql
│   ├── index.php
│   └── healthcheck.php
│
├── scripts
│   ├── bootstrap.sh
│   ├── deploy.sh
│   ├── backup.sh
│   ├── rollback.sh
│   ├── verify_deployment.sh
│   ├── prune_releases.sh
│   └── common.sh
│
├── docs
│
├── .github
│   └── workflows
│       └── deploy.yml
│
└── README.md
```

---

# Documentation

Additional documentation is available in the **docs/** directory.

- Architecture
- Deployment Guide
- Troubleshooting Guide

---

# Future Enhancements

- HTTPS using AWS Certificate Manager
- Route 53 DNS
- Blue/Green Deployments
- Terraform Infrastructure as Code
- AWS CodePipeline integration
- Containerization with Docker
- Amazon ECS deployment

---

# Author

**Rahul M**

GitHub

https://github.com/rahulmt007

---

# Version

Current Release

**v1.0-ssm-cicd**