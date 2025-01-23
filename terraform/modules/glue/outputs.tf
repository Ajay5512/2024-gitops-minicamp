
# modules/glue/outputs.tf
output "glue_database_name" {
  description = "Name of the created Glue catalog database"
  value       = aws_glue_catalog_database.database.name
}

output "glue_external_database_name" {
  description = "Name of the external Glue catalog database"
  value       = aws_glue_catalog_database.external.name
}

output "glue_crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.crawler.name
}


