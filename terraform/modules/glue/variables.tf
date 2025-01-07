
# modules/glue/variables.tf
variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

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

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for schema change notifications"
  type        = string
}


variable "redshift_database" {
  description = "Redshift database name"
  type        = string
}

variable "redshift_schema" {
  description = "Redshift schema name"
  type        = string
  default     = "public"
}

variable "redshift_workgroup_name" {
  description = "Redshift workgroup name"
  type        = string
}

variable "redshift_endpoint" {
  description = "Redshift endpoint"
  type        = string
}

variable "redshift_port" {
  description = "Redshift port"
  type        = string
}

variable "redshift_username" {
  description = "Redshift username"
  type        = string
}

variable "redshift_password" {
  description = "Redshift password"
  type        = string
  sensitive   = true
}

variable "availability_zone" {
  description = "Availability zone for the connection"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the connection"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the connection"
  type        = string
}
