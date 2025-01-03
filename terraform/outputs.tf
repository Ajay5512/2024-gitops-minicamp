
# outputs.tf (root)
output "source_bucket_name" {
  value = module.s3.source_bucket_id
}

output "target_bucket_name" {
  value = module.s3.target_bucket_id
}

output "glue_database_name" {
  value = module.glue.database_name
}

output "glue_crawler_name" {
  value = module.glue.crawler_name
}

output "glue_job_name" {
  value = module.glue.etl_job_name
}