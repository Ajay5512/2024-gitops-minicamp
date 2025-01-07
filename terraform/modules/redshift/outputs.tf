
<<<<<<< HEAD
# modules/redshift/outputs.tf
output "redshift_workgroup_id" {
  value       = aws_redshiftserverless_workgroup.serverless.id
  description = "ID of the Redshift Serverless workgroup"
}

output "redshift_namespace_id" {
  value       = aws_redshiftserverless_namespace.serverless.id
  description = "ID of the Redshift Serverless namespace"
}

output "redshift_database_name" {
  value = aws_redshiftserverless_namespace.serverless.db_name
}
=======
# Output values
output "redshift_database_name" {
  value = aws_redshiftserverless_namespace.serverless.db_name
}

output "redshift_workgroup_id" {
  value = aws_redshiftserverless_workgroup.serverless.id
}
>>>>>>> d68a768 (Updated the code)
