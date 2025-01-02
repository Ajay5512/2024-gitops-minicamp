
# File: terraform/modules/glue/outputs.tf
output "database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.org_report.name
}

output "crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.org_report.name
}

