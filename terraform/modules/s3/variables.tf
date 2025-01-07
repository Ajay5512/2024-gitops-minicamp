# modules/s3/variables.tf
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

variable "code_bucket" {
  description = "Name of the code bucket"
  type        = string
}

variable "script_path" {
  description = "Local path to the Glue job script"
  type        = string
}

variable "schema_change_script_path" {
  description = "Local path to the schema change detection script"
  type        = string
}

variable "organizations_csv_path" {
  description = "Path to the organizations CSV file"
  type        = string
}

variable "s3_to_redshift_script_path" {
  type        = string
  description = "Path to the S3 to Redshift ETL script"
}
