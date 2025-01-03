
# variables.tf (root)
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

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

variable "script_path" {
  description = "Local path to the Glue job script"
  type        = string
}
