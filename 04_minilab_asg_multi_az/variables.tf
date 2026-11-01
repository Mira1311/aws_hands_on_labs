variable "aws_region" {
	description	= "AWS Region to deploy the resources"
	type		= string
	default		= "ap-southeast-1"
}

variable "vpc_cidr" {
	description	= "CIDR block for the VPC"
	type		= string
	default		= "10.9.0.0/16"
}

