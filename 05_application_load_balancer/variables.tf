variable "aws_region" {
	description	= "AWS Region use to deploy resources"
	type		= string
	default		= "ap-southeast-1"
}

variable "vpc_cidr" {
	description	= "CIDR Block for the VPC"
	type		= string
	default		= "10.1.0.0/16"
}


