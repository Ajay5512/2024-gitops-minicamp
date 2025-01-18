
# modules/redshift/main.tf
resource "aws_redshiftserverless_namespace" "serverless" {
  namespace_name      = var.redshift_serverless_namespace_name
  db_name            = var.redshift_serverless_database_name
  admin_username     = var.redshift_serverless_admin_username
  admin_user_password = var.redshift_serverless_admin_password
  iam_roles          = [var.redshift_role_arn]
  tags = {
    Name = var.redshift_serverless_namespace_name
  }
}

resource "aws_redshiftserverless_workgroup" "serverless" {
  depends_on = [aws_redshiftserverless_namespace.serverless]
  namespace_name = aws_redshiftserverless_namespace.serverless.id
  workgroup_name = var.redshift_serverless_workgroup_name
  base_capacity  = var.redshift_serverless_base_capacity
  security_group_ids = [var.security_group_id]
  subnet_ids = var.subnet_ids
  publicly_accessible = var.redshift_serverless_publicly_accessible
  tags = {
    Name = var.redshift_serverless_workgroup_name
  }
}

resource "aws_redshiftserverless_usage_limit" "dbt_user_limit" {
  name           = "dbt-user-limit"
  usage_type     = "SERVERLESS_USAGE"
  amount         = 10
  period         = "MONTHLY"
  breach_action  = "LOG"
  resource_arn   = aws_redshiftserverless_namespace.serverless.arn
}