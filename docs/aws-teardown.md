# AWS Teardown Guide

## Purpose

This guide explains how to shut down the AWS Free Tier resources used by the Employee Management Application after the project has been documented.

The goal is to avoid ongoing AWS costs while preserving enough evidence for GitHub and portfolio review.

## Before You Delete Anything

Capture final proof of the working project:

- Application home page
- Edit Employee form with values prefilled
- GitHub Actions successful deployment
- ALB target group with healthy instances
- Auto Scaling Group details
- EC2 instances
- RDS database
- S3 artifact bucket
- CloudWatch dashboard and alarm
- Launch Template user data
- Systems Manager managed instances

Save screenshots under the existing `screenshots/` directory.

## Preserve Important Details

Record these non-secret details in documentation:

| Item | Value |
| --- | --- |
| Region | `us-east-1` |
| Auto Scaling Group | `capstone-asg` |
| Artifact Bucket | `rahulmt007-employee-management-artifacts` |
| Latest application version | `v3.0.0` |
| GitHub repository | `rahulmt007/employee-management-app` |

Do not document or commit:

- AWS access keys
- Database password
- Private keys
- Full account IDs if you do not want them public
- Sensitive RDS endpoint screenshots containing private details you do not want to expose

## Optional: Preserve Database Data

If you want to keep the sample data:

1. Take an RDS snapshot, or
2. Export the table data manually, or
3. Keep only screenshots if the data is not important.

For a portfolio project, screenshots are often enough.

## Recommended Teardown Order

Follow this order to avoid dependency errors and leftover costs.

### 1. Stop New Application Deployments

Avoid pushing new commits while tearing down resources.

Optional:

- Disable or ignore GitHub Actions deployment runs after infrastructure is removed.
- Keep the workflow file as documentation.

### 2. Scale Down the Auto Scaling Group

In AWS Console:

1. Open EC2.
2. Go to **Auto Scaling Groups**.
3. Select `capstone-asg`.
4. Set:

```text
Desired capacity: 0
Minimum capacity: 0
Maximum capacity: 0
```

Wait until instances terminate.

### 3. Delete the Auto Scaling Group

After capacity reaches zero:

1. Select the Auto Scaling Group.
2. Delete it.

### 4. Check EC2 Instances

Go to **EC2 > Instances**.

Confirm no project instances remain running.

Terminate any remaining project instances if needed.

### 5. Delete the Application Load Balancer

Go to **EC2 > Load Balancers**.

Delete the project ALB.

Then go to **Target Groups** and delete the project target group after the ALB is deleted.

### 6. Delete Launch Template

Go to **EC2 > Launch Templates**.

Delete the project launch template if it is no longer needed.

Keep `infrastructure/userdata.sh` in GitHub as the documented bootstrap source.

### 7. Delete or Stop RDS

Go to **RDS > Databases**.

Options:

- Delete the database if the project is complete.
- Take a final snapshot if you want a restore point.
- Skip final snapshot only if you do not need the data.

Also review:

- Manual snapshots
- Automated backups
- Subnet groups
- Parameter groups, if custom

Snapshots can continue to create storage cost.

### 8. Empty and Delete S3 Artifact Bucket

Go to **S3**.

1. Open `rahulmt007-employee-management-artifacts`.
2. Empty the bucket.
3. Delete the bucket if no longer needed.

If keeping the bucket as evidence, understand that stored artifacts may create small storage costs.

### 9. Delete CloudWatch Resources

Go to **CloudWatch**.

Delete project-specific:

- Dashboards
- Alarms
- Log groups, if any were created

### 10. Delete SNS Topic and Subscriptions

Go to **SNS**.

Delete project notification topics and subscriptions if they are no longer needed.

### 11. Review Security Groups

Go to **EC2 > Security Groups**.

Delete project-specific security groups after dependent resources are removed:

- ALB security group
- EC2 security group
- RDS security group

AWS will block deletion if a group is still attached.

### 12. Review Cost-Prone Leftovers

Check for:

- Running EC2 instances
- EBS volumes
- Elastic IP addresses
- NAT gateways
- Load balancers
- RDS snapshots
- S3 buckets
- CloudWatch logs

NAT gateways and load balancers are especially important because they can create charges even when instances are stopped.

## Final Billing Check

After teardown:

1. Open AWS Billing.
2. Check **Bills** and **Cost Explorer**.
3. Filter by region `us-east-1`.
4. Recheck after a few hours because some usage appears later.

## GitHub After Teardown

Update the README or release notes to say:

```text
The AWS environment was shut down after final documentation to avoid ongoing Free Tier costs. Screenshots and deployment documentation are retained in this repository.
```

The repository should still showcase:

- Application source code
- Deployment scripts
- GitHub Actions workflow
- Architecture docs
- Screenshots
- Troubleshooting notes
- Teardown process

## Rebuild Summary

To rebuild later:

1. Recreate AWS infrastructure.
2. Attach correct IAM instance profile.
3. Use `infrastructure/userdata.sh` in the Launch Template.
4. Configure GitHub secrets.
5. Set ASG desired capacity above zero.
6. Wait for instances to be `InService` and `Online` in SSM.
7. Run the GitHub Actions deployment workflow on `main`.

## Teardown Status Template

Use this checklist when completing teardown:

```text
[ ] Final screenshots captured
[ ] RDS data/snapshot decision completed
[ ] ASG scaled to zero
[ ] ASG deleted
[ ] EC2 instances terminated
[ ] ALB deleted
[ ] Target group deleted
[ ] Launch template deleted
[ ] RDS deleted or intentionally kept
[ ] S3 bucket emptied/deleted or intentionally kept
[ ] CloudWatch alarms/dashboard deleted
[ ] SNS topics/subscriptions deleted
[ ] Security groups deleted
[ ] EBS volumes checked
[ ] Elastic IPs checked
[ ] Billing reviewed
```
