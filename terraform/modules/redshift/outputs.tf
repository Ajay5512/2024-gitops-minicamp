# modules/redshift/outputs.tf

output "redshift_serverless_namespace_id" {
  description = "The ID of the Redshift Serverless namespace."
  value       = aws_redshiftserverless_namespace.serverless.id
}

output "redshift_serverless_workgroup_id" {
  description = "The ID of the Redshift Serverless workgroup."
  value       = aws_redshiftserverless_workgroup.serverless.id
}

output "redshift_serverless_endpoint" {
  description = "The endpoint of the Redshift Serverless workgroup."
  value       = aws_redshiftserverless_workgroup.serverless.endpoint[0].address
}