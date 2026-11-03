provider "aws" {
    region = "ap-southeast-1"
}

#1. Take ID of a using VPC (I'm using lab 5 currently)
data "aws_vpc" "existing_vpc" {
    id = "vpc-00336356f60eb2e8e"
}

#2. Create security group for the bastion (open port 22 to SSH from another outside devices)
resource "aws_security_group" "bastion_sg" {
    name = "lab8-bastion-sg"
    description = "Allow SSH from anywhere"
    vpc_id = data.aws_vpc.existing_vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # For real one it might be my IP but, just lab so i use 0.0.0.0/0 
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#3. Create Bastion host (Placed on Public Subnet)
resource "aws_instance" "bastion_host" {
    ami     = "ami-01127915c7b29e7ca"
    instance_type = "t3.micro"

    subnet_id = "subnet-052c4541959e5fd07"
    vpc_security_group_ids = [aws_security_group.bastion_sg.id]
    associate_public_ip_address = true

    tags = {
            Name = "Lab8-Bastion-Host"
    }
}

#4. Print the Public IP of the Bastion Host to use
output "bastion_public_ip" {
    value = aws_instance.bastion_host.public_ip
}

