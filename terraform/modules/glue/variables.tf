# Basic configuration variables
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

# Redshift connection variables
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

# Network configuration variables
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

# JDBC connection variables
variable "glue_jdbc_conn_name" {
  description = "Name for the Glue JDBC connection"
  type        = string
}

# Additional Glue job configuration
variable "glue_version" {
  description = "Version of Glue to use"
  type        = string
  default     = "4.0"
}

variable "number_of_workers" {
  description = "Number of workers for the Glue job"
  type        = number
  default     = 2
}

variable "timeout" {
  description = "Timeout for the Glue job in minutes"
  type        = number
  default     = 2880
}

# S3 configuration for utilities
variable "s3_utils_name" {
  description = "Name of the S3 bucket for Glue utilities"
  type        = string
}

variable "s3_utils_key" {
  description = "S3 key for the Glue job script"
  type        = string
}

# Optional Glue job parameters with defaults
variable "enable_job_insights" {
  description = "Enable job insights"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling"
  type        = bool
  default     = true
}

variable "enable_glue_datacatalog" {
  description = "Enable Glue data catalog"
  type        = bool
  default     = true
}

variable "job_language" {
  description = "Job language"
  type        = string
  default     = "python"
}

variable "job_bookmark_option" {
  description = "Job bookmark option"
  type        = string
  default     = "job-bookmark-enable"
}

variable "datalake_formats" {
  description = "Data lake formats"
  type        = string
  default     = "parquet"
}

variable "additional_conf" {
  description = "Additional configuration for the Glue job"
  type        = string
  default     = ""
}

ariable "s3_glue_catalog_database_name" {
  description = "Name of the S3 Glue catalog database"
  type        = string
}

variable "redshift_glue_catalog_database_name" {
  description = "Name of the Redshift Glue catalog database"
  type        = string
}

variable "s3_glue_crawler_name" {
  description = "Name of the S3 Glue crawler"
  type        = string
}

variable "redshift_glue_crawler_name" {
  description = "Name of the Redshift Glue crawler"
  type        = string
}