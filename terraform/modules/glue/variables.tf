variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "source_bucket_id" {
  description = "ID of the source S3 bucket"
  type        = string
}

variable "target_bucket_id" {
  description = "ID of the target S3 bucket"
  type        = string
}

variable "glue_service_role_arn" {
  description = "ARN of the Glue service role"
  type        = string
}
