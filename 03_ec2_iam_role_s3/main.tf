provider "aws" {
	region = var.aws_region
}

#1, Create a VPC
resource "aws_vpc" "my_lab3_vpc" {
	cidr_block		= var.vpc_cidr
	enable_dns_support	= true
	enable_dns_hostnames	= true
	tags = {
		Name = "Lab3-VPC"
	}
}

#2, Create a subnet
resource "aws_subnet" "my_lab3_subnet" {
	vpc_id			= aws_vpc.my_lab3_vpc.id
	cidr_block		= "10.7.0.0/24"
	availability_zone	= "${var.aws_region}a"
	map_public_ip_on_launch	= true
	tags = {
		Name = "Lab2-Public-Subnet"
	}
}
#3, Create an Internet Gateway (IGW)
resource "aws_internet_gateway" "my-lab3-igw" {
	vpc_id		= aws_vpc.my_lab3_vpc.id
	tags = {
		Name = "My-lab3-igw"
	}
}

#4, Create a Route Table 
resource "aws_route_table" "my-lab3-route-table" {
	vpc_id		= aws_vpc.my_lab3_vpc.id 
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.my-lab3-igw.id
	}
}
#5, Create an association route table
resource "aws_route_table_association" "my-lab3-rta" {
	subnet_id	= aws_subnet.my_lab3_subnet.id
	route_table_id  = aws_route_table.my-lab3-route-table.id
}

#6, Create a security group
resource "aws_security_group" "my-lab3-security-group" {
	name = "lab3-web-security-group"
	vpc_id = aws_vpc.my_lab3_vpc.id

	ingress {
		from_port	= 80
		to_port		= 80
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}
	
	ingress {
		from_port	= 22
		to_port		= 22
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}
	
	egress {
		from_port	= 0
		to_port		= 0
		protocol	= "-1"
		cidr_blocks	= ["0.0.0.0/0"]
	}
}

#7, Create a Private S3 Bucket
resource "aws_s3_bucket" "lab3_bucket" {
	bucket = "lab3-web-config-mira-2026"

	tags = {
		Name = "Lab3-Config-Bucket"
	}
}
#8, Upload a web configuration file into S3 bucket
resource "aws_s3_object" "index_file" {
	bucket	= aws_s3_bucket.lab3_bucket.id
	key	= "index.html"
	content = "<h1> Successfully! EC2 is automated use IAM Role to down this file from S3 Bucket! <h1/>"
}
#9.1, Create IAM Role
resource "aws_iam_role" "ec2_s3_role" {
	name = "lab3_ec2_s3_role" 

	assume_role_policy = jsonencode({
		Version = "2012-10-17"
		Statement = [{
			Action = "sts:AssumeRole"
			Effect = "Allow"
			Principal = {
				Service = "ec2.amazonaws.com"
			}
		}]
	})
}

#9.2, Allow readable S3 for role (Using default from AWS)
resource "aws_iam_role_policy_attachment" "s3_read_only" {
	role	= aws_iam_role.ec2_s3_role.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
#9.3, Create Instance Profile (Transform the Role into physical cards to attached to EC2)
resource "aws_iam_instance_profile" "ec2_s3_profile" {
	name = "lab3-ec2-s3-profile"
	role = aws_iam_role.ec2_s3_role.name
}
#10, Create EC2 Instance
resource "aws_instance" "my_lab3_server" {
	ami		= "ami-0e683f46a1f00df41"
        instance_type   = "t3.micro" 

	subnet_id              = aws_subnet.my_lab3_subnet.id
        vpc_security_group_ids = [aws_security_group.my-lab3-security-group.id]

        #Attached legal physical cards into the server
        iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name

        user_data = <<-EOF
                    #!/bin/bash
                    apt-get update -y
                    apt-get install -y apache2 awscli
                    systemctl start apache2
                    systemctl enable apache2
                    
		    # Using commands of IAM Role, call the AWS CLI to download file from S3 to override default web
                    aws s3 cp s3://${aws_s3_bucket.lab3_bucket.id}/index.html /var/www/html/index.html
                    EOF

        tags = { Name = "Lab3-IAM-Web-Server" }
}






