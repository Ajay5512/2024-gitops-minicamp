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