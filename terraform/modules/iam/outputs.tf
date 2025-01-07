
# modules/iam/outputs.tf
output "glue_role_arn" {
  value = aws_iam_role.glue_service_role.arn
}

output "redshift_role_arn" {
  value = aws_iam_role.redshift_serverless_role.arn
}