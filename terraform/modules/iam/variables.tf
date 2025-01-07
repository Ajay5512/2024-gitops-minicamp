variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
}

variable "source_bucket" {
  type        = string
  description = "Name of the source S3 bucket"
}