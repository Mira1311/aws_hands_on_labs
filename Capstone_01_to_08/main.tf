provider "aws" {
    region = var.aws_region
}

#1. Create a VPC
resource "aws_vpc" "my_capstone_project_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "Capstone-VPC"
    }
}
#2.1. Create a public subnet 1a
resource "aws_subnet" "my_1st_public_subnet" {
    vpc_id = aws_vpc.my_capstone_project_vpc.id
    cidr_block = "10.5.1.0/24"
    availability_zone = "${var.aws_region}a"
    map_public_ip_on_launch = true
    tags = {
        Name = "Capstone-Public-Subnet-1a"
    }
}
#2.2 Create a public subnet 1b
resource "aws_subnet" "my_2nd_public_subnet" {
    vpc_id = aws_vpc.my_capstone_project_vpc.id
    cidr_block = "10.5.2.0/24"
    availability_zone = "${var.aws_region}b"
    map_public_ip_on_launch = true
    tags = {
        Name = "Capstone-Public-Subnet-1b"
    }
}
#3.1. Create a private subnet 1a
resource "aws_subnet" "my_1st_private_subnet" {
    vpc_id = aws_vpc.my_capstone_project_vpc.id
    cidr_block = "10.5.3.0/24"
    availability_zone = "${var.aws_region}a"
    tags = {
        Name = "Capstone-Private-Subnet-1a"
    }
}

#3.2. Create a private subnet 1b
resource "aws_subnet" "my_2nd_private_subnet" {
    vpc_id = aws_vpc.my_capstone_project_vpc.id
    cidr_block = "10.5.4.0/24"
    availability_zone = "${var.aws_region}b"
    tags = {
        Name = "Capstone-Private-Subnet-1b"
    }
}

#4. Create a Internet Gateway for public subnet
resource "aws_internet_gateway" "capstone_igw" {
    vpc_id = aws_vpc.my_capstone_project_vpc.id
    tags = {
        Name = "My-Capstone-IGW"
    }
}
#5. Create a Route Table 
resource "aws_route_table" "capstone_rt" {
    vpc_id = aws_vpc.my_capstone_project_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.capstone_igw.id
    }
}
#6. Create a route table association for 2 public subnet
resource "aws_route_table_association" "my_capstone_rta_1a" {
    subnet_id = aws_subnet.my_1st_public_subnet.id
    route_table_id = aws_route_table.capstone_rt.id
}
resource "aws_route_table_association" "my_capstone_rta_1b" {
    subnet_id = aws_subnet.my_2nd_public_subnet.id
    route_table_id = aws_route_table.capstone_rt.id
}

#7 Create security group for the bastion 
resource "aws_security_group" "capstone_bastion_sg" {
    name = "capstone-bastion-sg"
    description = "Allow SSH from anywhere"
    vpc_id = aws_vpc.my_capstone_project_vpc.id

    ingress {
         from_port = 22
         to_port = 22
         protocol = "tcp"
         cidr_blocks = ["0.0.0.0/0"] #I used my home IP as well, but commit to git i'll make it back to 0.0.0.0
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#8. Create Bastion Host (placed on public subnet 1a) 
resource "aws_instance" "capstone_bastion_host" {
    ami = "ami-01127915c7b29e7ca"
    instance_type = "t3.micro"

    subnet_id = aws_subnet.my_1st_public_subnet.id
    vpc_security_group_ids = [aws_security_group.capstone_bastion_sg.id]
    associate_public_ip_address = true
    
    key_name = "capstone-key"

    tags = {
        Name = "My-Capstone-Bastion-Host"
    }
}
#9. Get the public IP of Bastion 
output "bastion_public_ip" {
    value = aws_instance.capstone_bastion_host.public_ip
}

#10. Get random password with 16 words length, which not have illegal words of RDS
resource "random_password" "corp-db-password" {
    length = 16
    special = true
    override_special = "!#%^&*()-_=+" #Saved words for MySQL
}

#11. Create a secret box to hidden the password inside
resource "aws_secretsmanager_secret" "capstone_rds_secret" {
    name = "capstone/rds/mysql-admin-password"
    description = "Master password for Capstone Project RDS"
}

#12. Open secret box, take the secret password which just created and sent into the secret box
resource "aws_secretsmanager_secret_version" "capstone-rds-server-version" {
    secret_id = aws_secretsmanager_secret.capstone_rds_secret.id
    secret_string = random_password.corp-db-password.result
}

#13. Display ID of the secret box (w/o pwd, optional) and only use for another labs (if needed) 
output "secret_arn" {
    value = aws_secretsmanager_secret.capstone_rds_secret.arn
}
#14. Create Security Group for RDS 
resource "aws_security_group" "rds-sg" {
    name = "capstone_rds-sg"
    description = "Allow MySQL traffic from EC2 ASG"
    vpc_id = aws_vpc.my_capstone_project_vpc.id

    # Accept connection from Bastion Host
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.capstone_bastion_sg.id, aws_security_group.capstone-ec2-sg.id]
    }

}
#15. Create DB Subnet Group from 2 private subnet
resource "aws_db_subnet_group" "capstone_rds_subnet_group" {
    name = "capstone-rds-subnet-group"
    subnet_ids = [aws_subnet.my_1st_private_subnet.id, aws_subnet.my_2nd_private_subnet.id]

    tags = {
        Name = "Capstone_DB_Subnet_Group"
    }
}

#16, Create core database (Amazon RDS - MySQL)
resource "aws_db_instance" "capstone_database" {
    allocated_storage = 20
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    identifier = "capstone-mysql-db"
    username = "admin"
    password = aws_secretsmanager_secret_version.capstone-rds-server-version.secret_string
    skip_final_snapshot = true
    publicly_accessible = false

    vpc_security_group_ids = [aws_security_group.rds-sg.id]
    db_subnet_group_name = aws_db_subnet_group.capstone_rds_subnet_group.name
}

#17. Create Security Group for EC2
resource "aws_security_group" "capstone-ec2-sg" {
    name = "capstone-ec2-sg"
    description = "Allow"
    vpc_id = aws_vpc.my_capstone_project_vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.capstone-alb-sg.id]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.capstone_bastion_sg.id]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#18. Create Security Group for ALB
resource "aws_security_group" "capstone-alb-sg" {
    name = "capstone-alb-sg"
    description = "Allow HTTP from internet"
    vpc_id = aws_vpc.my_capstone_project_vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0  
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#19. Create a target group for ALB
resource "aws_lb_target_group" "capstone-target-group" {
    name = "capstone-target-group"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.my_capstone_project_vpc.id
}
#20. Create an ALB (Application Load Balancer) 
resource "aws_lb" "my-capstone-alb" {
    name = "capstone-alb"
    internal = false
    load_balancer_type = "application"

    #Attached security groups to the albs
    security_groups = [aws_security_group.capstone-alb-sg.id]

    #Command ALB to stay in both subnets
    subnets         = [
        aws_subnet.my_1st_public_subnet.id,
        aws_subnet.my_2nd_public_subnet.id
    ]
}
resource "aws_lb_listener" "capstone-listener" {
    load_balancer_arn = aws_lb.my-capstone-alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.capstone-target-group.arn
    }
}

#21. Create a Launch template
resource "aws_launch_template" "capstone-lt" {
    name_prefix = "capstone-web-template-"
    image_id      = "ami-0e683f46a1f00df41"
    instance_type = "t3.micro"

    vpc_security_group_ids = [aws_security_group.capstone-ec2-sg.id]

    user_data = base64encode(<<EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx 
    EOF
    )
}
#22. Auto Scaling Group
resource "aws_autoscaling_group" "capstone-asg" {
    name = "capstone-asg"
    desired_capacity = 2
    min_size = 2
    max_size = 4

    vpc_zone_identifier = [
        aws_subnet.my_1st_private_subnet.id,
        aws_subnet.my_2nd_private_subnet.id
    ]
    target_group_arns = [aws_lb_target_group.capstone-target-group.arn]

    launch_template {
      id = aws_launch_template.capstone-lt.id
      version = "$Latest"
    }
    tag {
        key = "Name"
        value = "Capstone-Server"
        propagate_at_launch = true
    }
}
#23. Create an Elastic IP
resource "aws_eip" "capstone_nat_eip" {
    domain = "vpc"
    tags = {
        Name = "Capstone-NAT-EIP"
    }
}
#24. Setup the NAT gateway stand on the public subnet
resource "aws_nat_gateway" "capstone_nat" {
    allocation_id = aws_eip.capstone_nat_eip.id
    subnet_id = aws_subnet.my_1st_public_subnet.id

    tags = {
        Name = "Capstone-NAT-Gateway"
    }
    #IGW public need to run before we called NAT
    depends_on = [aws_internet_gateway.capstone_igw]
}
#25, Create a route table only for private subnet
resource "aws_route_table" "capstone-private-rt" {
    vpc_id = aws_vpc.my_capstone_project_vpc.id

    #Rule: Anyone in private subnet need to go out, it must transfer to NAT go instead of them
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.capstone_nat.id
    }
    tags = {
        Name = "Capstone-Private-Route-Table"
    }
}
#26. Give the private route table to subnets 
resource "aws_route_table_association" "private-rta-1st" {
    subnet_id = aws_subnet.my_1st_private_subnet.id
    route_table_id = aws_route_table.capstone-private-rt.id

}
resource "aws_route_table_association" "private-rta-2nd" {
    subnet_id = aws_subnet.my_2nd_private_subnet.id
    route_table_id = aws_route_table.capstone-private-rt.id
}
