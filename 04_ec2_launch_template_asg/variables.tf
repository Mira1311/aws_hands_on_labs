variable "aws_region" {
	description	= "AWS region to deploy resources"
	type		= string
	default		= "ap-southeast-1"
}

variable "vpc_cidr" {
	description	= "CIDR Block for the VPC"
	type		= string
	default		= "10.8.0.0/16"
}

