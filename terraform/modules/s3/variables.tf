
# modules/s3/variables.tf
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

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "script_path" {
  description = "Local path to the Glue job script"
  type        = string
}


# Update modules/s3/variables.tf
variable "schema_change_script_path" {
  description = "Local path to the schema change detection script"
  type        = string
}
