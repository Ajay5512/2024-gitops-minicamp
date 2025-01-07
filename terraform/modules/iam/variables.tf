
# modules/iam/variables.tf
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
