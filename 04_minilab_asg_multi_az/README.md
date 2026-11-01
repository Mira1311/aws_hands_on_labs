# Lab 04.5: Multi-AZ Auto Scaling Group & High Availability Architecture

## 📝 Overview
This lab extends the foundation of Auto Scaling by introducing **High Availability (HA)** and **Fault Tolerance** across multiple Availability Zones (AZs) on AWS. By deploying resources across distinct data centers, the infrastructure can survive an entire AZ outage without downtime.

## 🏗️ Architecture Design
- **Network Core:** 1 Custom VPC (`10.9.0.0/16`) with an attached Internet Gateway.
- **Multi-AZ Subnets:** 
  - `Subnet-1a` in AZ `ap-southeast-1a`
  - `Subnet-1b` in AZ `ap-southeast-1b`
- **Routing:** 1 shared Route Table associated with both public subnets to enable internet access.
- **Compute (Launch Template):** An immutable EC2 blueprint provisioning Ubuntu with an automated Apache Web Server setup via base64 `user_data`.
- **Scaling (Auto Scaling Group):** 
  - Spans across both `Subnet-1a` and `Subnet-1b`.
  - Automatically balances instances across AZs.
  - Configuration: Desired: 2, Min: 2, Max: 4.

## 🚀 Key Learnings
- **Fault Tolerance:** Designing architectures that span multiple physical locations.
- **Terraform DRY Principle (Don't Repeat Yourself):** Reusing a single Route Table and associating it with multiple subnets via `aws_route_table_association`.
- **ASG Zone Balancing:** Understanding how the `vpc_zone_identifier` parameter instructs the ASG to distribute EC2 instances evenly across configured AZs.

## 🛠️ Usage
1. Initialize the working directory: `terraform init`
2. Validate and review the infrastructure: `terraform plan`
3. Provision the Multi-AZ environment: `terraform apply`
4. Clean up to avoid AWS charges: `terraform destroy`
