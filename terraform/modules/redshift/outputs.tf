
# modules/redshift/outputs.tf
output "redshift_namespace_id" {
  description = "ID of the created Redshift Serverless namespace"
  value       = aws_redshiftserverless_namespace.serverless.id
}

output "redshift_workgroup_id" {
  description = "ID of the created Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.serverless.id
}

output "redshift_endpoint" {
  description = "Endpoint for the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.serverless.endpoint
}


output "redshift_port" {
  description = "Port for Redshift connection"
  value       = "5439"
}

output "redshift_database_name" {
  description = "Database name for Redshift connection"
  value       = var.redshift_serverless_database_name
}