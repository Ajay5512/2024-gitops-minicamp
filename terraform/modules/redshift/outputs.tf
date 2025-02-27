output "redshift_endpoint" {
  description = "The endpoint of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.serverless.endpoint
}

output "redshift_namespace_id" {
  description = "The ID of the Redshift Serverless namespace"
  value       = aws_redshiftserverless_namespace.serverless.id
}

output "redshift_workgroup_id" {
  description = "The ID of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.serverless.id
}