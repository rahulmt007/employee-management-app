# AWS Employee Management Application

## Tech Stack

- PHP
- Apache
- AWS EC2
- Amazon RDS MySQL
- GitHub
- AWS CodeDeploy
- GitHub Actions
- CloudWatch
- SNS

## Features

- Add Employee
- View Employees
- Store data in Amazon RDS
- Health Check Endpoint
- CI/CD Deployment
- Cloud Monitoring

## Architecture

GitHub
      ↓
GitHub Actions
      ↓
AWS CodeDeploy
      ↓
EC2 (Apache + PHP)
      ↓
Amazon RDS MySQL

## Monitoring

- CloudWatch Dashboard
- CPU Alarm
- SNS Notification

## Future Improvements

- Auto Scaling
- Application Load Balancer
- Route53
- ACM HTTPS
- Terraform