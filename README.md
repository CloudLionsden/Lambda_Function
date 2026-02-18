Implemented an AWS Lambda function that runs within a specified VPC and automatically deletes EC2 snapshots older than one year.

---

I used **Terraform** because it lets me define the VPC, subnet, IAM role, Lambda, and EventBridge schedule in one place, making deployment repeatable and safe. I package the Lambda code as `lambda.zip`, and Terraform uploads it automatically when applied. The Lambda runs in the VPC using the private subnet and security group I defined. I assumed a default AWS region and a 365-day snapshot retention. Execution is monitored via **CloudWatch Logs** and metrics for errors and invocations.

---
# Snapshot Cleanup Automation (AWS Lambda + Terraform)

## Overview
This project provisions AWS infrastructure using Terraform and deploys an AWS Lambda function
that automatically deletes EBS snapshots older than one year.

The Lambda function runs inside a private subnet within a VPC and is triggered daily using an
EventBridge (CloudWatch Events) scheduled rule.

---

## Infrastructure as Code Tool Choice
**Terraform** was chosen because:
- It is widely used for cloud infrastructure provisioning
- It supports modular, reusable configuration
- It is cloud-agnostic and well suited for CI/CD automation

---

## Infrastructure Created
Terraform provisions the following resources:
- VPC
- Private subnet
- Private route table + association
- Security group for Lambda
- IAM Role and IAM Policy for Lambda
- Lambda function deployed inside the VPC
- EventBridge scheduled rule (daily trigger)
- VPC Interface Endpoint for EC2 API (to allow private API access)

---

## Lambda Function Behavior
The Lambda function:
- Retrieves all EBS snapshots owned by the account
- Filters snapshots older than 365 days (based on StartTime)
- Deletes snapshots older than the retention period
- Logs each deletion attempt
- Includes basic error handling

---

## How to Deploy

### Step 1: Package the Lambda
Navigate to the lambda directory:

cd lambda
chmod +x build.sh
This creates lambda.zip.

Step 2: Deploy Infrastructure
Navigate to the terraform directory:
./build.sh
cd terraform
terraform init
terraform plan
terraform apply
