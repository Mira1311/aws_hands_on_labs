#1, Declaration AWS Provider
provider "aws" {
	region = "ap-southeast-1"
}

#2, Getting/Create a VPC
resource "aws_vpc" "my_1st_lab_vpc" {
	cidr_block		= "10.5.0.0/16"
	enable_dns_support	= true
	enable_dns_hostnames	= true

	tags = {
		Name = "Lab-Monolithic-VPC"
	}
}

#3, Create Public Subnet
resource "aws_subnet" "my_1st_public_subnet" {
	vpc_id			= aws_vpc.my_1st_lab_vpc.id
	cidr_block		= "10.5.1.0/24"
	availability_zone	= "ap-southeast-1a"
	map_public_ip_on_launch = true

	tags = {
		Name = "Lab-Public-Subnet"
	}
}

#4, Create Internet Gateway (IGW)
resource "aws_internet_gateway" "my_1st_igw" {
	vpc_id = aws_vpc.my_1st_lab_vpc.id

	tags = {
		Name = "Lab-IGW"
	}
}

#5, Create Route Table
resource "aws_route_table" "my_1st_public_rt" {
	vpc_id = aws_vpc.my_1st_lab_vpc.id

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.my_1st_igw.id
	}

	tags = {
		Name = "Lab-Public_RT"
	}
}

#6, Create route table association
resource "aws_route_table_association" "my_1st_rta" {
	subnet_id	= aws_subnet.my_1st_public_subnet.id
	route_table_id	= aws_route_table.my_1st_public_rt.id
}

#7, Building firewall (Security Group) for the server
resource "aws_security_group" "my_web_sg" {
	name		= "lab-web-sg"
	description	= "Allow SSH and HTTP inbound traffic"
	vpc_id		= aws_vpc.my_1st_lab_vpc.id

	#Rule to allow inbound
	ingress {
		description	= "Allow SSH from everywhere"
		from_port	= 22
		to_port		= 22
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}
	
	ingress {
		description	= "Allow HTTP for web traffic"
		from_port	= 80
		to_port		= 80
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}
	
	#Rule to allow outbound 
	egress {
		from_port	= 0
		to_port		= 0
		protocol	= "-1" 
		cidr_blocks	= ["0.0.0.0/0"]
	}

	tags = {
		Name = "Lab-Web-SG"
	}
}
#8, Create an EC2 Instance
resource "aws_instance" "my_web_server" {
	ami		= "ami-0e683f46a1f00df41"
	instance_type	= "t3.micro"

	subnet_id = aws_subnet.my_1st_public_subnet.id
	vpc_security_group_ids = [aws_security_group.my_web_sg.id]

	tags = {
		Name = "Lab-Web-Server"
	}
}

