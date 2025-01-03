

# modules/glue/variables.tf
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
