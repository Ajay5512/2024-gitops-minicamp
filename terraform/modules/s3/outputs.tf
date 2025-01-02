

# File: terraform/modules/s3/outputs.tf
output "source_bucket_id" {
  value = aws_s3_bucket.source_data.id
}

output "target_bucket_id" {
  value = aws_s3_bucket.target_data.id
}

output "code_bucket_id" {
  value = aws_s3_bucket.code.id
}
