provider "aws" {
	region = var.aws_region
}

#1, Create a VPC
resource "aws_vpc" "my_minilab_1_vpc" {
	cidr_block		= var.vpc_cidr
	enable_dns_support	= true
	enable_dns_hostnames	= true
	tags = {
		Name = "Minilab-VPC"
	}
}
#2.1, Create first subnet at AZs southeast 1a
resource "aws_subnet" "my_subnet_1a" {
	vpc_id			= aws_vpc.my_minilab_1_vpc.id
	cidr_block		= "10.9.1.0/24"
	availability_zone	= "${var.aws_region}a"
	map_public_ip_on_launch = true
	
	tags = {
		Name = "My_Minilab_1st_public_subnet"
	}
}

#2.2, Create second subnet at AZs southeast 1b
resource "aws_subnet" "my_subnet_1b" {
	vpc_id			= aws_vpc.my_minilab_1_vpc.id
	cidr_block		= "10.9.2.0/24"
	availability_zone	= "${var.aws_region}b"
	map_public_ip_on_launch	= true

	tags = {
		Name = "My_Minilab_2nd_public_subnet"
	}
}
#3, Create an Internet Gateway (IGW)
resource "aws_internet_gateway" "my_minilab_igw" {
	vpc_id			= aws_vpc.my_minilab_1_vpc.id
	tags = {
		Name = "My-minilab-igw"
	}
}

#4, Create a route table
resource "aws_route_table" "my_minilab_rt" {
	vpc_id	= aws_vpc.my_minilab_1_vpc.id

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.my_minilab_igw.id
	}
}
#5.1, Create route table association for subnet 1a
resource "aws_route_table_association" "my_1a_rta" {
	subnet_id = aws_subnet.my_subnet_1a.id
	route_table_id = aws_route_table.my_minilab_rt.id
}

#5.2, Create route table association for subnet 1b
resource "aws_route_table_association" "my_1b_rta" {
	subnet_id = aws_subnet.my_subnet_1b.id
	route_table_id = aws_route_table.my_minilab_rt.id
}
#6, Create a security group
resource "aws_security_group" "my_minilab_security_group" {
	name	= "minilab-web-security-group"
	vpc_id	= aws_vpc.my_minilab_1_vpc.id

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
#7, Create a launch template
resource "aws_launch_template" "my_minilab_launchtemplate" {
	name_prefix	= "minilab-web-template-"
	image_id	= "ami-0e683f46a1f00df41"
	instance_type	= "t3.micro"

	#Attached Security Group into the form
	vpc_security_group_ids = [aws_security_group.my_minilab_security_group.id]

	 #Encoding base64 script to setting the webserver
        user_data = base64encode(<<-EOF
                    #!/bin/bash
                    apt-get update -y
                    apt-get install -y apache2
                    systemctl start apache2
                    systemctl enable apache2
                    echo "<h1>The system run Multi-Az successfully</h1>" > /var/www/html/index.html
                    EOF
        )
}
#8, Create auto scaling group
resource "aws_autoscaling_group" "my-minilab-asg" {
	name			= "my-minilab-asg"
	vpc_zone_identifier	= [
			aws_subnet.my_subnet_1a.id,
			aws_subnet.my_subnet_1b.id
		]

	#Strategy
	desired_capacity	= 2
	max_size		= 4
	min_size		= 2

	#Given original prototype template to create based on
	launch_template {
		id = aws_launch_template.my_minilab_launchtemplate.id
		version = "$Latest"
	}
	
	#Automatically tagged into new instanced which created by ASG
	tag {
		key			= "name"
		value			= "Multi-AZ-WebServer"
		propagate_at_launch	= true
	}
}

		

