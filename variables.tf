variable "environment" {
  description = "Environment"
  default     = "staging"
}

variable "aws_region" {
  default = "ap-southeast-1"
}

// VPC
variable "vpc_name" {
  description = "VPC Name"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
}

variable "whitelist_ip" {
  description = "Whitelist IP"
}