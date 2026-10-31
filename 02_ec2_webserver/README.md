# Lab 02: Web Server Automation & Elastic IP

## Scenario
Provision a highly available web server infrastructure. The EC2 instance must automatically
install and start an Apache HTTP server upon boot using `user_data`. To ensure DNS reliability, an Elastic IP (EIP) is
attached to provide a static public IP address. Code is structured into multiple files
(`main.tf`, `variables.tf`, `outputs.tf`) following Terraform best practices.

## Architecture
1. **Networking:** VPC, Public Subnet, IGW, and Route Table.
2. **Security:** Security Group allowing SSH (22) and HTTP (80)
3. **Compute:** EC2 instance with an automated bootstrap script (User data)
4. **Networking (Static):** Elastic IP attached to the EC2 instance.

## Learning Objectives
- Use `user_data` to bootstrap EC2 instances 
- Allocate and associate AWS Elastic IP addresses
- Decouple hardcoded values using `variables.tf` and extract results using `outputs.tf`.
