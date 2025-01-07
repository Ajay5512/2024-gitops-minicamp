
# modules/iam/variables.tf
variable "app_name" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (dev/staging/prod)"
}

variable "source_bucket" {
  type        = string
  description = "Name of the source data bucket"
}

variable "target_bucket" {
  type        = string
  description = "Name of the target data bucket"
}