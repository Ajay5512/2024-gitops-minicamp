
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


output "source_bucket_suffix" {
  value = var.source_bucket
}

output "target_bucket_suffix" {
  value = var.target_bucket
}



# Add to your existing terraform/outputs.tf
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}



output "redshift_role_arn" {
  description = "ARN of the Redshift serverless role"
  value       = aws_iam_role.redshift-serverless-role.arn
}