AWS 3-Tier Web Architecture with Terraform 🚀
This repository contains the Terraform configuration for a highly available, secure, and scalable 3-Tier Web Architecture on AWS. This project serves as a Capstone for AWS Certified Solutions Architect - Associate (SAA-C03) preparation.

🏗️ Architecture Overview
The infrastructure is provisioned entirely via Infrastructure as Code (IaC) using Terraform and strictly adheres to AWS well-architected framework best practices.

Key components:
Networking: Custom VPC with 2 Public Subnets and 4 Private Subnets spread across 2 Availability Zones for High Availability (HA).
Routing & NAT: Internet Gateway (IGW) for public access and a NAT Gateway to allow instances in private subnets to securely download updates.
Security (Security Group Chaining):
ALB SG: Only accepts HTTP (80) traffic from the public internet.
EC2 Web SG: Only accepts traffic routed from the ALB and SSH from the Bastion Host.
RDS SG: Only accepts MySQL (3306) connections from the EC2 Web SG.
Compute (Auto Scaling): Nginx web servers running on EC2 instances inside an Auto Scaling Group (ASG), automatically deployed via Launch Templates with dynamic user_data bootstrapping.
Load Balancing: Application Load Balancer (ALB) distributing incoming internet traffic across the EC2 instances in private subnets.
Database: Amazon RDS (MySQL) deployed in a private DB Subnet Group.
Secrets Management: Admin database credentials dynamically generated and securely stored in AWS Secrets Manager (No hardcoded passwords).
Management: Bastion Host deployed in the public subnet for secure SSH administration.

🛠️ Prerequisites
Terraform installed (v1.0.0+)
AWS CLI installed and configured (aws configure)
An active AWS account

🚀 Usage Instructions
Clone the repository:
git clone <your-repository-url>
cd <repository-folder>

Initialize Terraform:
terraform init

Review the deployment plan:
terraform plan

Provision the infrastructure:
terraform apply
# Type 'yes' when prompted

Verify the Deployment:
Navigate to the AWS Console -> EC2 -> Load Balancers.
Copy the DNS name of the ALB and paste it into your browser.
You should see the Nginx welcome page displaying the Hostname, proving the ALB is routing traffic to your ASG!
🧹 Cleanup

To avoid incurring future AWS charges, destroy the resources once you are done experimenting:
terraform destroy
# Type 'yes' when prompted
