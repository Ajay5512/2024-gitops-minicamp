# modules/redshift/outputs.tf

output "redshift_workgroup_id" {
  value       = aws_redshiftserverless_workgroup.serverless.id
  description = "ID of the Redshift Serverless workgroup"
}

output "redshift_namespace_id" {
  value       = aws_redshiftserverless_namespace.serverless.id
  description = "ID of the Redshift Serverless namespace"
}

output "redshift_security_group_id" {
  value       = aws_security_group.redshift-serverless-sg.id
  description = "ID of the Redshift security group"
}

output "redshift_role_arn" {
  value       = aws_iam_role.redshift-serverless-role.arn
  description = "ARN of the Redshift IAM role"
}


output "redshift_database_name" {
  value = aws_redshiftserverless_namespace.serverless.db_name
}

