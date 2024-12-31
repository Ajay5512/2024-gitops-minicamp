variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "raw_bucket_id" {
  description = "ID of the raw data bucket"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of the Glue service role"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
