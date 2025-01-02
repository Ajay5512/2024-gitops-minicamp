
# File: terraform/modules/iam/outputs.tf
output "glue_service_role_arn" {
  value = aws_iam_role.glue_service.arn
}