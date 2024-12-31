output "database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.enterprise_data_catalog.name
}

output "crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.org_master_crawler.name
}