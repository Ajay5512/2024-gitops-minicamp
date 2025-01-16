# variables.tf

########################
## AWS - Variables ##
########################
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

########################
## S3 - Variables ##
########################
variable "source_bucket" {
  description = "Name of the source data bucket"
  type        = string
}

variable "target_bucket" {
  description = "Name of the target data bucket"
  type        = string
}

variable "code_bucket" {
  description = "Name of the code bucket"
  type        = string
}

############################# 
## Application - Variables ##
#############################
variable "app_name" {
  type        = string
  description = "Application name"
}

#########################
## Network - Variables ##
#########################
variable "redshift_serverless_vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR"
}

variable "redshift_serverless_subnet_1_cidr" {
  type        = string
  description = "IPv4 CIDR for Redshift subnet 1"
}

variable "redshift_serverless_subnet_2_cidr" {
  type        = string
  description = "IPv4 CIDR for Redshift subnet 2"
}

variable "redshift_serverless_subnet_3_cidr" {
  type        = string
  description = "IPv4 CIDR for Redshift subnet 3"
}

#####################################
## Redshift Serverless - Variables ##
#####################################
variable "redshift_serverless_namespace_name" {
  type        = string
  description = "Redshift Serverless Namespace Name"
}

variable "redshift_serverless_database_name" {
  type        = string
  description = "Redshift Serverless Database Name"
}

variable "redshift_serverless_admin_username" {
  type        = string
  description = "Redshift Serverless Admin Username"
}

variable "redshift_serverless_admin_password" {
  type        = string
  description = "Redshift Serverless Admin Password"
  sensitive   = true
}

variable "redshift_serverless_workgroup_name" {
  type        = string
  description = "Redshift Serverless Workgroup Name"
}

variable "redshift_serverless_base_capacity" {
  type        = number
  description = "Redshift Serverless Base Capacity"
  default     = 32 // 32 RPUs to 512 RPUs in units of 8 (32,40,48...512)
}

variable "redshift_serverless_publicly_accessible" {
  type        = bool
  description = "Set the Redshift Serverless to be Publicly Accessible"
  default     = false
}

#######################
## EC2 - Variables ##
#######################
variable "ami_id" {
  type        = string
  description = "ID of the AMI to use for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Type of EC2 instance"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "public_key" {
  type        = string
  description = "Public SSH key for EC2 instance access"
  sensitive   = true
}