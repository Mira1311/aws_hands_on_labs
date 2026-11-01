# Lab 03: EC2 with IAM Role and S3 Integration

## Scenario
Create a private S3 bucket to store a website configuration file. Provision an EC2 (Ubuntu) instance and attach an IAM Role to it, granting read-only access to S3. The instance will use `user_data` to automatically download the file from S3 and start a web server without hardcoding any AWS credentials.

## Architecture
1. **Networking:** VPC, Public Subnet, IGW, Route Table, Security Group (Port 80, 22).
2. **Storage:** Private Amazon S3 Bucket.
3. **Security (Identity):** IAM Role and IAM Instance Profile for EC2.
4. **Compute:** EC2 instance (Ubuntu) fetching data from S3 during bootstrap.
