# modules/redshift/variables.tf

variable "redshift_serverless_namespace_name" {
  description = "The name of the Redshift Serverless namespace."
  type        = string
}

variable "redshift_serverless_database_name" {
  description = "The name of the Redshift Serverless database."
  type        = string
}

variable "redshift_serverless_admin_username" {
  description = "The admin username for the Redshift Serverless namespace."
  type        = string
}

variable "redshift_serverless_admin_password" {
  description = "The admin password for the Redshift Serverless namespace."
  type        = string
  sensitive   = true
}

variable "redshift_role_arn" {
  description = "The ARN of the IAM role for Redshift Serverless."
  type        = string
}

variable "redshift_serverless_workgroup_name" {
  description = "The name of the Redshift Serverless workgroup."
  type        = string
}

variable "redshift_serverless_base_capacity" {
  description = "The base capacity for the Redshift Serverless workgroup."
  type        = number
}

variable "security_group_id" {
  description = "The ID of the security group for the Redshift Serverless workgroup."
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the public subnet where the Redshift Serverless workgroup will be deployed."
  type        = string
}

variable "dbt_password" {
  description = "The password for the dbt user in Redshift."
  type        = string
  sensitive   = true
}

