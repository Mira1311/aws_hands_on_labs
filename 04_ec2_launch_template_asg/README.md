# Lab 04: Highly Available Infrastructure with AWS Auto Scaling Group & Launch Template

## 📝 Overview
This repository demonstrates how to provision a highly available and scalable web infrastructure on AWS using Terraform. It replaces the traditional standalone EC2 instance approach with a dynamic **Auto Scaling Group (ASG)** backed by a **Launch Template**.

## 🏗️ Architecture Diagram & Resources
The Terraform configuration provisions the following AWS resources:
- **Networking Core:** VPC, Public Subnet, Internet Gateway (IGW), and Route Table.
- **Security:** Security Group with inbound rules for HTTP (port 80) and SSH (port 22).
- **Compute (Launch Template):** A standardized blueprint for EC2 instances utilizing an Ubuntu AMI, `t3.micro` instance type, and a base64-encoded `user_data` script to automatically bootstrap an Apache Web Server.
- **Scaling (Auto Scaling Group):** Automatically manages the EC2 fleet to ensure high availability.
  - `Desired Capacity:` 2 instances
  - `Minimum Size:` 1 instance
  - `Maximum Size:` 4 instances

## 🚀 Key Learnings
- **Infrastructure as Code (IaC):** Automating scalable architectures without manual console clicks.
- **Fleet Management:** Utilizing Launch Templates over legacy Launch Configurations for better version control and feature support.
- **High Availability:** Ensuring web servers are automatically replaced or scaled out based on ASG configurations.
- **Terraform FinOps:** Understanding `wait_for_capacity_timeout` to optimize deployment times and actively destroying environments to avoid unnecessary cloud costs.

## 🛠️ How to Use

1. **Initialize Terraform:**
   ```bash
   terraform init
