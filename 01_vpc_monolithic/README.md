# Lab 01: Monolithic VPC & EC2 deployment

## Requirement Scenario
Deploy a VPC infrastructure on AWS and place an EC2 inside this to connect to the Internet. 
All the infrastructure is declared in only a file named "main.tf" to understand about Dependency methods in Terraform.

## Deployment infrastructure ( Architecture )
1. **VPC:** CIDR Block: `10.5.0.0/16`
2. **Public Subnet:** 1 AZs in AZ `ap-southeast-1a`
3. **Internet Gateway (IGW) & Route Table:**: A gate and a map allow Subnets connect to the internet
4. **Security Group:** A firewall only opened for SSH (Port 22) and HTTP (port 80)
5. **EC2 Instance:** Create new amazon linux EC2 Instance, placed in Public Subnet

## Learning Objectives
- Know how the AWS resources are implicitly linked together via the attribute 'id'
- Differentiate between "State" of Terraform when doing in real production.
