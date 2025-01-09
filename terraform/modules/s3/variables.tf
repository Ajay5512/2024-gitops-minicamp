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

variable "source_files" {
  description = "Map of source data file names to their local paths"
  type        = map(string)
  default     = {}
}

variable "code_files" {
  description = "Map of code file names to their local paths"
  type        = map(string)
  default     = {}
}

