# Instance Variables
variable "ami_id" {
  description = "AMI ID for the Nexabrands EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the Nexabrands EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the Nexabrands EC2 instance will be launched"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the Nexabrands security group will be created"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile for Nexabrands"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the Nexabrands project"
  type        = string
  default     = "nexabrands"
}

variable "source_bucket" {
  description = "Name of the Nexabrands source S3 bucket"
  type        = string
}

variable "target_bucket" {
  description = "Name of the Nexabrands target S3 bucket"
  type        = string
}

variable "code_bucket" {
  description = "Name of the Nexabrands code S3 bucket"
  type        = string
}
