provider "aws" {
    region = "ap-southeast-1"
}

#1. Create Security Group Chaining, only EC2 accepted
resource "aws_security_group" "rds_sg" {
    name = "lab6_rds_sg"
    description = "Allow MySQL traffic from EC2 ASG"
    vpc_id = "vpc-00336356f60eb2e8e"
    #I use my lab 5 to create terraform, then the vpc_id and some exclusives data here will based on my lab 5 after terraform apply successfully.
    

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = ["sg-000bd356d2e78a949"]
    }
}

#2. Create DB Subnet Group from 2 Private Subnet
resource "aws_db_subnet_group" "rds_subnet_group" {
    name = "lab6-rds-subnet-group" 
    subnet_ids = ["subnet-052c4541959e5fd07", "subnet-01b2a94a8c9bb3452"]
    
    tags = {
      Name = "Lab6_DB_Subnet_Group"
    }
}

#4. Block Data (This one connected to my labs-07) to tell the Terraform take data from the secret box
data "aws_secretsmanager_secret_version" "my_secret_password" {
    secret_id = "lab7/rds/mysql-admin-password"
}


#3. Create Core of the Database (Amazon RDS - MySQL)
resource "aws_db_instance" "my_database" {
    allocated_storage = 20
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    identifier = "lab6-mysql-db"
    username = "admin"
    password = data.aws_secretsmanager_secret_version.my_secret_password.secret_string
    skip_final_snapshot = true
    publicly_accessible = false

    vpc_security_group_ids = [aws_security_group.rds_sg.id]
    db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name   
}

