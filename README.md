# Lambda_Function
Implemented an AWS Lambda function that runs within a specified VPC and automatically deletes EC2 snapshots older than one year.

---

I used **Terraform** because it lets me define the VPC, subnet, IAM role, Lambda, and EventBridge schedule in one place, making deployment repeatable and safe. I package the Lambda code as `lambda.zip`, and Terraform uploads it automatically when applied. The Lambda runs in the VPC using the private subnet and security group I defined. I assumed a default AWS region and a 365-day snapshot retention. Execution is monitored via **CloudWatch Logs** and metrics for errors and invocations.

---
