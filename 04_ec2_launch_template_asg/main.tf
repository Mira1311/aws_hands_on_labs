provider "aws" {
	region = var.aws_region
}

#1, Create a VPC 
resource "aws_vpc" "my_lab4_vpc" {
	cidr_block		= var.vpc_cidr
	enable_dns_support	= true
	enable_dns_hostnames	= true
	tags = {
		Name = "Lab4_vpc"
	}
}

#2, Create a subnet
resource "aws_subnet" "my_lab4_subnet" {
	vpc_id		= aws_vpc.my_lab4_vpc.id
	cidr_block	= "10.8.0.0/24"
	availability_zone = "${var.aws_region}a"
	map_public_ip_on_launch = true
	tags = {
		Name = "Lab4_Public_Subnet"
	}
}

#3, Create an internet gateway
resource "aws_internet_gateway" "my_lab4_igw" {
	vpc_id = aws_vpc.my_lab4_vpc.id
	tags = {
		Name = "My-lab4-igw"
	}
}
#4, Create a route table
resource "aws_route_table" "my_lab4_route_table" {
	vpc_id = aws_vpc.my_lab4_vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.my_lab4_igw.id
	}
}

#5, Create an association route table
resource "aws_route_table_association" "my_lab4_rta" {
	subnet_id	= aws_subnet.my_lab4_subnet.id
	route_table_id	= aws_route_table.my_lab4_route_table.id
}

#6, Create a security group
resource "aws_security_group" "my_lab4_sec_group" {
	name = "lab4-web-security-group"
	vpc_id = aws_vpc.my_lab4_vpc.id

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
#7, Create a Launch Template (Setup a form for the server) 
resource "aws_launch_template" "my_lab4_lt" {
	name_prefix	= "lab4-web-template-"
	image_id	= "ami-0e683f46a1f00df41"
	instance_type	= "t3.micro"
		
	#Attached Security Group into the form
	vpc_security_group_ids = [aws_security_group.my_lab4_sec_group.id]
	
	#Encoding base64 script to setting the webserver
	user_data = base64encode(<<-EOF
                    #!/bin/bash
                    apt-get update -y
                    apt-get install -y apache2
                    systemctl start apache2
                    systemctl enable apache2
                    echo "<h1>Successfully launch the server which created by Launch Template!</h1>" > /var/www/html/index.html
                    EOF
        )
}
#8, Create auto scaling group
resource "aws_autoscaling_group" "my_lab4_asg" {
	name		= "lab4-web-asg"
	vpc_zone_identifier = [aws_subnet.my_lab4_subnet.id]

	#Strategy
	desired_capacity	= 2
	max_size		= 4
	min_size		= 1

	#Which original prototype template use to create?
	launch_template {
		id = aws_launch_template.my_lab4_lt.id
		version = "$Latest"
	}

	#This tag is automatically attached into all EC2 instances which created by ASG
	tag {
		key			= "name"
		value			= "Lab4-ASG-WebServer"
		propagate_at_launch	= true
	}
}

