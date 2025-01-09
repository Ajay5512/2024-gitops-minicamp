
# Variables
variable "source_bucket" {
  description = "Source bucket ID"
  type        = string
}

variable "target_bucket" {
  description = "Target bucket ID"
  type        = string
}

variable "code_bucket" {
  description = "Code bucket ID"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of the Glue service role"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for schema change notifications"
  type        = string
}

variable "redshift_database" {
  type        = string
  description = "Redshift database name"
}

variable "redshift_schema" {
  type        = string
  description = "Redshift schema name"
  default     = "public"
}

variable "redshift_workgroup_name" {
  type        = string
  description = "Redshift workgroup name"
}
