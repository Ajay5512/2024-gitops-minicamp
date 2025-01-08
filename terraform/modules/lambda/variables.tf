
# terraform/modules/lambda/variables.tf
variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "source_bucket" {
  description = "Name of the source bucket suffix"
  type        = string
}

variable "target_bucket" {
  description = "Name of the target bucket suffix"
  type        = string
}
