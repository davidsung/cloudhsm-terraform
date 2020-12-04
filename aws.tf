terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = "~> 2.8"
  region  = var.aws_region
}
