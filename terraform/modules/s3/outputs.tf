# modules/s3/outputs.tf
output "source_bucket_name" {
  value = aws_s3_bucket.source_bucket.id
}

output "target_bucket_name" {
  value = aws_s3_bucket.target_bucket.id
}

output "source_bucket_id" {
  value = aws_s3_bucket.source_bucket.id
}

output "target_bucket_id" {
  value = aws_s3_bucket.target_bucket.id
}

output "code_bucket_id" {
  value = aws_s3_bucket.code_bucket.id
}
