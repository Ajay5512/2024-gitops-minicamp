
# modules/glue/outputs.tf
output "database_name" {
  value = aws_glue_catalog_database.database.name
}

output "crawler_name" {
  value = aws_glue_crawler.crawler.name
}

output "etl_job_name" {
  value = aws_glue_job.etl_job.name
}
