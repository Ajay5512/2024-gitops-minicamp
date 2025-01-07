variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "source_bucket" {
  type        = string
  description = "Name of the source S3 bucket"
}

variable "target_bucket" {
  type        = string
  description = "Name of the target S3 bucket"
}

variable "code_bucket" {
  type        = string
  description = "Name of the code bucket"
}