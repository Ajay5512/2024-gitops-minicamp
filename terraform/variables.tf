variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name for resource tagging"
  type        = string
  default     = "enterprise-data"
}

variable "credentials_file" {
  description = "Path to AWS credentials file"
  type        = string
  default     = "C:/Users/DHEERA~1/.aws/credentials"
}