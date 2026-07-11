# AWS Employee Management Application

![Employee dashboard screenshot](screenshots/application/dashboard_v3.2.0.png)

## Overview

The **AWS Employee Management Application** is a PHP and MySQL employee directory deployed on AWS with an automated CI/CD pipeline.

This project demonstrates both application development and DevOps delivery:

- PHP employee management application
- Amazon RDS MySQL database integration
- GitHub Actions CI/CD pipeline
- S3-based deployment artifact storage
- AWS Systems Manager deployment to EC2 instances
- Release-based deployments with rollback support
- Application Load Balancer in front of an Auto Scaling Group
- CloudWatch monitoring and alarms
- Docker Compose local development stack
- Kubernetes-ready deployment manifests

> Cost note: the live AWS environment may be stopped or deleted after documentation to avoid ongoing AWS Free Tier usage. Screenshots and documentation are included so the project remains reviewable when the infrastructure is offline.

## Features

- Add employee records
- View employee directory
- Search employees by name
- Edit employee name and address
- Delete employee records
- Session-based admin authentication
- Health check endpoint for deployment verification
- Release-based deployment under `/opt/employee-app`
- Local Docker Compose environment
- Kubernetes manifests for local clusters or future EKS deployment

## Latest Release

| Item | Value |
| --- | --- |
| Application version | `v3.2.0` |
| Containerization release | `v3.1.0` |
| Authentication/session fix commit | `5000fc9` |
| Employee edit feature commit | `25d9f90` |
| Region | `us-east-1` |
| Auto Scaling Group | `capstone-asg` |
| Artifact bucket | `rahulmt007-employee-management-artifacts` |

## Screenshots

### Application

![Login page](screenshots/application/login_v3.2.0.png)

![Authenticated employee dashboard](screenshots/application/dashboard_v3.2.0.png)

![Employee edit form](screenshots/application/edit_employee_v3.2.0.png)

### Architecture

![Architecture diagram](screenshots/architecture/architecture_diagram.png)

### GitHub Actions

![GitHub Actions deployment](screenshots/github-actions/github-actions.png)

### AWS Resources

| Resource | Screenshot |
| --- | --- |
| Application Load Balancer | [alb.png](screenshots/aws/alb.png) |
| Auto Scaling Group | [asg.png](screenshots/aws/asg.png) |
| EC2 Instances | [instances.png](screenshots/aws/instances.png) |
| RDS MySQL | [rds.png](screenshots/aws/rds.png) |
| S3 Artifact Bucket | [s3.png](screenshots/aws/s3.png) |
| Launch Template | [launch template.png](screenshots/aws/launch%20template.png) |
| IAM | [IAM.png](screenshots/aws/IAM.png) |
| VPC | [vpc.png](screenshots/aws/vpc.png) |
| CloudWatch Dashboard | [dashboard.png](screenshots/monitoring/dashboard.png) |
| CloudWatch Alarm | [alarm.png](screenshots/monitoring/alarm.png) |

## Architecture

```text
Developer
  |
  v
GitHub Repository
  |
  v
GitHub Actions
  |
  +--> Build deployment artifact
  |
  +--> Upload artifact to Amazon S3
  |
  +--> Discover InService EC2 instances in Auto Scaling Group
  |
  +--> Send AWS Systems Manager command
          |
          v
       EC2 Instances
       Apache + PHP + PHP-FPM
          |
          v
       /opt/employee-app/current
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

## AWS Services Used

| Service | Purpose |
| --- | --- |
| Amazon EC2 | Hosts Apache and PHP application runtime |
| Auto Scaling Group | Replaces unhealthy instances and supports scaling |
| Application Load Balancer | Routes user traffic to healthy EC2 instances |
| Amazon RDS MySQL | Stores employee data |
| Amazon S3 | Stores deployment artifacts |
| AWS Systems Manager | Runs deployment commands without SSH |
| AWS IAM | Controls EC2, S3, SSM, and GitHub Actions permissions |
| Amazon CloudWatch | Provides dashboard, metrics, and alarms |
| Amazon SNS | Sends alarm notifications |
| GitHub Actions | Builds, uploads, and deploys application releases |

## CI/CD Pipeline

The workflow in `.github/workflows/deploy.yml` runs on pushes to `main` and can also be started manually.

```text
Push to main
  |
  v
Validate repository structure
  |
  v
Generate VERSION and manifest.json
  |
  v
Package app/ and scripts/ into a ZIP artifact
  |
  v
Upload artifact to GitHub Actions and Amazon S3
  |
  v
Find InService instances in capstone-asg
  |
  v
Verify instances are Online in SSM
  |
  v
Run bootstrap.sh and deploy.sh through SSM
  |
  v
Create release directory and update current symlink
  |
  v
Restart PHP-FPM and Apache
  |
  v
Verify http://localhost/healthcheck.php returns 200
```

## Containerized Local Development

The project can run locally with Docker Compose:

```bash
docker compose up --build
```

Local URL:

```text
http://localhost:8080
```

The Compose stack runs:

- PHP 8.2 + Apache application container
- MySQL 8.0 database container
- Docker health checks for app and database

See [Containerization Guide](docs/containerization.md).

## Authentication

The app includes simple PHP session authentication.

- Login is required before viewing or changing employee records.
- Passwords are stored with PHP `password_hash()`.
- Session data is stored in MySQL so authentication works across ALB-routed EC2 instances.
- The initial admin user is seeded from `AUTH_ADMIN_USER` and `AUTH_ADMIN_PASS`.
- Local demo defaults are `admin` / `ChangeMe123!`.

For AWS or any shared environment, configure stronger credentials before deployment.

See [Authentication Guide](docs/authentication.md).

## Kubernetes Manifests

Kubernetes manifests are included under `k8s/` for local demos or future production adaptation:

- App Deployment with two replicas
- ClusterIP Service
- ConfigMap and Secret example
- Readiness and liveness probes
- Optional Ingress
- Optional HorizontalPodAutoscaler
- Optional local MySQL manifest for `kind`, `minikube`, or Docker Desktop Kubernetes

See [Kubernetes Guide](docs/kubernetes.md).

## Release-Based Deployment

Application files are deployed to timestamped release directories:

```text
/opt/employee-app
|-- current -> releases/<active-release>
|-- releases/
|-- backups/
|-- logs/
`-- scripts/
```

Benefits:

- Fast rollback by repointing the `current` symlink
- Clear release history on each instance
- Safer deployments than overwriting files in place
- Health check verification before declaring success

## Important Operational Lessons

- Fresh Auto Scaling instances only run the EC2 bootstrap. The GitHub Actions deployment must run after instances are `InService` and `Online` in SSM.
- Seeing Apache's `It works!` page means the instance bootstrapped but the application deployment has not completed or Apache is not pointed at the app release.
- PHP output can remain stale if PHP-FPM is not restarted. The deployment now restarts PHP-FPM when available, then restarts Apache.
- The live ALB URL is useful for testing, but screenshots are the durable portfolio artifact once Free Tier resources are terminated.

## Documentation

- [Architecture](docs/architecture.md)
- [Deployment Guide](docs/deployment-guide.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Containerization Guide](docs/containerization.md)
- [Kubernetes Guide](docs/kubernetes.md)
- [v3.1.0 Release Notes](docs/releases/v3.1.0.md)
- [Authentication Guide](docs/authentication.md)
- [v3.2.0 Release Notes](docs/releases/v3.2.0.md)
- [AWS Teardown Guide](docs/aws-teardown.md)

## Repository Structure

```text
.
|-- .github/workflows/deploy.yml
|-- app/
|   |-- assets/
|   |-- sql/database.sql
|   |-- healthcheck.php
|   `-- index.php
|-- docs/
|-- k8s/
|-- infrastructure/userdata.sh
|-- scripts/
|-- screenshots/
|-- Dockerfile
|-- docker-compose.yml
`-- README.md
```

## Future Enhancements

- HTTPS using AWS Certificate Manager
- Route 53 DNS record
- GitHub OIDC instead of long-lived AWS access keys
- Terraform infrastructure as code
- Blue/green or rolling deployment strategy
- Prepared SQL statements and CSRF protection
- Publish container image to a registry
- Amazon EKS or ECS production deployment

## Author

Rahul M  
GitHub: <https://github.com/rahulmt007>
