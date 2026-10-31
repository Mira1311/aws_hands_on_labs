variable "aws_region" {
	description	= "The AWS Region to deploy resources"
	type		= string
	default		= "ap-southeast-1"
}

variable "vpc_cidr" {
	description	= "CIDR block for the VPC"
	type		= string
	default		= "10.6.0.0/16"
}

