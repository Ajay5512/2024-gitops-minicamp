variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "source_bucket" {
  description = "Name suffix of the source data bucket (will be prefixed with nexabrands-{environment}-)"
  type        = string
}

variable "target_bucket" {
  description = "Name suffix of the target data bucket (will be prefixed with nexabrands-{environment}-)"
  type        = string
}

variable "code_bucket" {
  description = "Name suffix of the code bucket (will be prefixed with nexabrands-{environment}-)"
  type        = string
}

variable "source_files" {
  description = "Map of source data file names to their local paths for upload to source bucket"
  type        = map(string)
  default     = {}
}

variable "code_files" {
  description = "Map of code file names to their local paths for upload to code bucket under scripts/ directory"
  type        = map(string)
  default     = {}
}

variable "kms_deletion_window" {
  description = "Duration in days before KMS key is deleted"
  type        = number
  default     = 7
}

variable "lifecycle_ia_transition_days" {
  description = "Number of days before transitioning non-current versions to STANDARD_IA storage"
  type        = number
  default     = 30
}

variable "lifecycle_glacier_transition_days" {
  description = "Number of days before transitioning non-current versions to GLACIER storage"
  type        = number
  default     = 60
}

variable "lifecycle_expiration_days" {
  description = "Number of days before deleting non-current versions"
  type        = number
  default     = 90
}

variable "object_lock_retention_days" {
  description = "Number of days for S3 Object Lock retention period in COMPLIANCE mode"
  type        = number
  default     = 1
}