
# File: terraform/modules/s3/variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}