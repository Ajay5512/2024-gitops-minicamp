
# modules/iam/outputs.tf
output "glue_role_arn" {
  value = aws_iam_role.glue_service_role.arn
}


# Output the Redshift role ARN
output "redshift_role_arn" {
  value = aws_iam_role.redshift-serverless-role.arn
}

