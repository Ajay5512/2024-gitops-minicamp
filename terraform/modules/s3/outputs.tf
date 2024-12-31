output "raw_bucket_id" {
  description = "ID of the raw data bucket"
  value       = aws_s3_bucket.enterprise_raw_data.id
}

output "processed_bucket_id" {
  description = "ID of the processed data bucket"
  value       = aws_s3_bucket.enterprise_processed_data.id
}

output "scripts_bucket_id" {
  description = "ID of the ETL scripts bucket"
  value       = aws_s3_bucket.enterprise_etl_scripts.id
}