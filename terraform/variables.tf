variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # Changed to match GitHub Actions configuration
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"  # Default to prod since your workflow uses production environment
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "topdevs"
}