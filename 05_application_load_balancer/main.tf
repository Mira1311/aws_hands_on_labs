provider "aws" {
	region = var.aws_region
}

#1, Create a VPC
resource "aws_vpc" "my_lab5_vpc" {
	cidr_block		= var.vpc_cidr
	enable_dns_support	= true
	enable_dns_hostnames	= true
	tags = {
		Name = "My_Lab5_VPC"
	}
}

#2.1, Create 1st subnet
resource "aws_subnet" "my_lab5_subnet_1a" {
	vpc_id			= aws_vpc.my_lab5_vpc.id
	cidr_block		= "10.1.1.0/24"
	availability_zone	= "${var.aws_region}a" 
	map_public_ip_on_launch	= true
	tags = {
		Name = "Lab5_Subnet_1a"
	}
}
#2.2, Create 2nd subnet
resource "aws_subnet" "my_lab5_subnet_1b" {
	vpc_id			= aws_vpc.my_lab5_vpc.id
	cidr_block		= "10.1.2.0/24"
	availability_zone	= "${var.aws_region}b"
	map_public_ip_on_launch	= true
	tags = {
		Name = "Lab5_Subnet_1b"
	}
}
#3, Create an IGW
resource "aws_internet_gateway" "my_lab5_igw" {
	vpc_id		= aws_vpc.my_lab5_vpc.id
	tags = {
		Name = "My_lab5_igw"
	}
}
#4, Create a route table
resource "aws_route_table" "my_lab5_route_table" {
	vpc_id		= aws_vpc.my_lab5_vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.my_lab5_igw.id
	}
}
#5.1, Create a route table association for subnet 1a
resource "aws_route_table_association" "my_lab5_subnet1a_rta" {
	subnet_id = aws_subnet.my_lab5_subnet_1a.id
	route_table_id = aws_route_table.my_lab5_route_table.id
}
#5.2, Create a route table association for subnet 1b
resource "aws_route_table_association" "my_lab5_subnet1b_rta" {
	subnet_id = aws_subnet.my_lab5_subnet_1b.id
	route_table_id = aws_route_table.my_lab5_route_table.id
}

#6.1, Create a security group for alb 
resource "aws_security_group" "alb_sg" {
	name = "alb_sg" 
	vpc_id = aws_vpc.my_lab5_vpc.id

	ingress {
		from_port	= 80
		to_port		= 80
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
#6.2, Create a security group for web
resource "aws_security_group" "web_sg" {
	name = "web-sg"
	vpc_id = aws_vpc.my_lab5_vpc.id

	ingress {
		from_port	= 80
		to_port		= 80
		protocol	= "tcp"
		security_groups = [aws_security_group.alb_sg.id]
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

#### LOAD BALANCER SETUP
#7, Create a target group

resource "aws_lb_target_group" "my_lab5_target_group" {
	name	= "lab5-target-group"
	port	= 80
	protocol = "HTTP" 
	vpc_id	= aws_vpc.my_lab5_vpc.id
}

#8, Create an ALB (Application Load Balancer)
resource "aws_lb" "my_lab5_alb" {
	name		= "lab5-alb"
	internal	= false
	load_balancer_type = "application"

	#Attached security group to the albs
	security_groups = [aws_security_group.alb_sg.id]

	#Command Albs stay both subnets
	subnets		= [
		aws_subnet.my_lab5_subnet_1a.id,
		aws_subnet.my_lab5_subnet_1b.id
		]
}

resource "aws_lb_listener" "my_lab5_listener" {
        # Gắn đôi tai này vào đúng cô Lễ tân bằng số CCCD (ARN)
        load_balancer_arn = aws_lb.my_lab5_alb.arn
        port              = "80"
        protocol          = "HTTP"

        # Khách gọi cổng 80 thì mở "Sổ chấm công" ra để đẩy khách vào
        default_action {
                type             = "forward"
                target_group_arn = aws_lb_target_group.my_lab5_target_group.arn
        }
}

# 10. Create a Launch Template
resource "aws_launch_template" "my_lab5_lt" {
        name_prefix   = "lab5-web-template-"
        image_id      = "ami-0e683f46a1f00df41"
        instance_type = "t3.micro"

        
        vpc_security_group_ids = [aws_security_group.web_sg.id]

        user_data = base64encode(<<-EOF
                    #!/bin/bash
                    apt-get update -y
                    apt-get install -y apache2
                    systemctl start apache2
                    systemctl enable apache2
                    echo "<h1>Thanh cong! Traffic dang di qua ALB!</h1>" > /var/www/html/index.html
                    EOF
        )
}

# 11.Auto Scaling Group
resource "aws_autoscaling_group" "my_lab5_asg" {
        name                = "my-lab5-asg"
        desired_capacity    = 2
        max_size            = 4
        min_size            = 2
        
        
        vpc_zone_identifier = [
                aws_subnet.my_lab5_subnet_1a.id,
                aws_subnet.my_lab5_subnet_1b.id
        ]

        target_group_arns = [aws_lb_target_group.my_lab5_target_group.arn]

        launch_template {
                id      = aws_launch_template.my_lab5_lt.id
                version = "$Latest"
        }

        tag {
                key                 = "Name"
                value               = "Lab5-Web-Server"
                propagate_at_launch = true
        }
}
