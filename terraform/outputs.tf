
# File: terraform/outputs.tf
output "raw_bucket_name" {
  description = "Name of the raw data bucket"
  value       = module.s3.raw_bucket_id
}

output "processed_bucket_name" {
  description = "Name of the processed data bucket"
  value       = module.s3.processed_bucket_id
}

output "glue_database_name" {
  description = "Name of the Glue catalog database"
  value       = module.glue.database_name
}