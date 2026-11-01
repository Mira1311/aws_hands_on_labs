variable "aws_region" {
	description	= "AWS region to deploy resources"
	type		= string
	default		= "ap-southeast-1"
}

variable "vpc_cidr" {
	description	= "CIDR block for the VPC"
	type		= string
	default		= "10.7.0.0/16"
}

	
