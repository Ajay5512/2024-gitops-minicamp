# modules/glue/variables.tf

# Environment and Infrastructure Variables
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "source_bucket" {
  description = "Name of the S3 bucket containing source data"
  type        = string
}

variable "target_bucket" {
  description = "Name of the S3 bucket for processed data"
  type        = string
}

variable "code_bucket" {
  description = "Name of the S3 bucket containing Glue scripts"
  type        = string
}

# IAM Role for Glue
variable "glue_role_arn" {
  description = "ARN of the IAM role for Glue services"
  type        = string
}
