resource "aws_glue_catalog_database" "org_report" {
  name         = "${var.project}-${var.environment}-org-report"
  location_uri = "s3://${var.source_bucket_id}/"
}

resource "aws_glue_crawler" "org_report" {
  name          = "${var.project}-${var.environment}-org-report"
  database_name = aws_glue_catalog_database.org_report.name
  role          = var.glue_service_role_arn

  s3_target {
    path = "s3://${var.source_bucket_id}/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  tags = {
    Environment = var.environment
    Project     = var.project
    Managed_by  = "terraform"
  }
}

resource "aws_glue_trigger" "org_report" {
  name = "${var.project}-${var.environment}-org-report"
  type = "ON_DEMAND"

  actions {
    crawler_name = aws_glue_crawler.org_report.name
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    Managed_by  = "terraform"
  }
}




# Update modules/glue/main.tf
resource "aws_glue_job" "schema_change_job" {
  name              = "topdevs-${var.environment}-schema-change-job"
  role_arn          = var.glue_role_arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 2880
  max_retries       = 1

  command {
    name            = "pythonshell"
    python_version  = "3"
    script_location = "s3://${var.code_bucket}/schema_change.py"
  }

  default_arguments = {
    "--catalog_id" = data.aws_caller_identity.current.account_id
    "--db_name"    = aws_glue_catalog_database.database.name
    "--table_name" = "your_table_name"
    "--topic_arn"  = var.sns_topic_arn
  }
} 