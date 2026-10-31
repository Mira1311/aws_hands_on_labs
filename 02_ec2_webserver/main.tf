provider "aws" {
	region = var.aws_region
}

#1, Create basic VPC network blocks
resource "aws_vpc" "lab2_vpc" {
	cidr_block		= var.vpc_cidr
	enable_dns_support	= true
	enable_dns_hostnames	= true
	tags = {
		Name = "Lab2-VPC"
	}
}
resource "aws_subnet" "lab2_public_subnet" {
	vpc_id			= aws_vpc.lab2_vpc.id
	cidr_block		= "10.6.1.0/24"
	availability_zone	= "${var.aws_region}a"
	map_public_ip_on_launch = true
	tags = {
		Name = "Lab2-public-subnet"
	}
}

resource "aws_internet_gateway" "lab2_igw" {
	vpc_id	= aws_vpc.lab2_vpc.id
	tags	= {
		Name = "Lab2-igw"
	}
}

resource "aws_route_table" "lab2_rt" {
	vpc_id = aws_vpc.lab2_vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.lab2_igw.id
	}
}

resource "aws_route_table_association" "lab2_rta" {
	subnet_id	= aws_subnet.lab2_public_subnet.id
	route_table_id	= aws_route_table.lab2_rt.id
}

resource "aws_security_group" "lab2_sg" {
	name = "lab2-web-sg"
	vpc_id = aws_vpc.lab2_vpc.id

	ingress {
		from_port = 22
		to_port	  = 22
		protocol  = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	ingress {
		from_port = 80
		to_port	  = 80
		protocol  = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	egress {
		from_port = 0
		to_port	  = 0
		protocol  = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}
resource "aws_instance" "web_server" {
  ami           = "ami-0e683f46a1f00df41" # Ubuntu AMI
  instance_type = "t3.micro"
  
  subnet_id              = aws_subnet.lab2_public_subnet.id
  vpc_security_group_ids = [aws_security_group.lab2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Deploy thanh cong Web Server tren Ubuntu bang Terraform!</h1>" > /var/www/html/index.html
              EOF

  tags = { Name = "Lab2-Automated-Web-Ubuntu" }
}
resource "aws_eip" "web_eip" {
  instance = aws_instance.web_server.id
  domain   = "vpc"

  tags = { Name = "Lab2-Static-IP" }
}
