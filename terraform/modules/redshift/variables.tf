
# modules/redshift/variables.tf
<<<<<<< HEAD
variable "app_name" {
  type        = string
  description = "Application name"
}

variable "redshift_serverless_namespace_name" {
  type        = string
  description = "Redshift Serverless Namespace Name"
}

variable "redshift_serverless_database_name" {
  type        = string
  description = "Redshift Serverless Database Name"
}

variable "redshift_serverless_admin_username" {
  type        = string
  description = "Redshift Serverless Admin Username"
}

variable "redshift_serverless_admin_password" {
  type        = string
=======
variable "redshift_serverless_namespace_name" {
  type        = string
  description = "Redshift Serverless Namespace Name"
}

variable "redshift_serverless_database_name" {
  type        = string
  description = "Redshift Serverless Database Name"
}

variable "redshift_serverless_admin_username" {
  type        = string
  description = "Redshift Serverless Admin Username"
}

variable "redshift_serverless_admin_password" {
  type        = string
>>>>>>> cd2c14e (uPDATE)
  description = "Redshift Serverless Admin Password"
}

variable "redshift_serverless_workgroup_name" {
  type        = string
  description = "Redshift Serverless Workgroup Name"
}

variable "redshift_serverless_base_capacity" {
  type        = number
  description = "Redshift Serverless Base Capacity"
  default     = 32
}

variable "redshift_serverless_publicly_accessible" {
  type        = bool
  description = "Set the Redshift Serverless to be Publicly Accessible"
  default     = false
}

variable "redshift_role_arn" {
  type        = string
  description = "ARN of the IAM role for Redshift"
}

variable "security_group_id" {
  type        = string
<<<<<<< HEAD
  description = "Security group ID for Redshift"
=======
  description = "ID of the security group for Redshift"
>>>>>>> cd2c14e (uPDATE)
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for Redshift"
<<<<<<< HEAD
}
=======
}
>>>>>>> cd2c14e (uPDATE)
