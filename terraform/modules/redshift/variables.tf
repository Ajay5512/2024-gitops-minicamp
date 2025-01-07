# modules/redshift/variables.tf

variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for Redshift"
}

variable "source_bucket" {
  type        = string
  description = "Name of the source S3 bucket"
}

variable "target_bucket" {
  type        = string
  description = "Name of the target S3 bucket"
}

variable "redshift_serverless_namespace_name" {
  type        = string
  description = "Name of the Redshift Serverless namespace"
}

variable "redshift_serverless_database_name" {
  type        = string
  description = "Name of the Redshift database"
}

variable "redshift_serverless_admin_username" {
  type        = string
  description = "Admin username for Redshift"
}

variable "redshift_serverless_admin_password" {
  type        = string
  description = "Admin password for Redshift"
  sensitive   = true
}

variable "redshift_serverless_base_capacity" {
  type        = number
  description = "Base capacity for Redshift Serverless in RPUs"
  default     = 32
}

variable "glue_role_arn" {
  type        = string
  description = "ARN of the Glue service role"
}