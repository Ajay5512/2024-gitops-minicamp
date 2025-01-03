output "source_bucket_name" {
  description = "Name of the source data bucket"
  value       = module.s3.source_bucket_id
}

output "target_bucket_name" {
  description = "Name of the target data bucket"
  value       = module.s3.target_bucket_id
}

output "glue_database_name" {
  description = "Name of the Glue catalog database"
  value       = module.glue.database_name
}
