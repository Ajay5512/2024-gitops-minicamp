
# modules/glue/main.tf
resource "aws_glue_catalog_database" "database" {
  name = "topdevs-${var.environment}-org-report"
}

resource "aws_glue_crawler" "crawler" {
  name          = "topdevs-${var.environment}-org-report-crawler"
  database_name = aws_glue_catalog_database.database.name
  role          = var.glue_role_arn
  
  s3_target {
    path = "s3://${var.source_bucket}/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
  }
}

resource "aws_glue_job" "etl_job" {
  name              = "topdevs-${var.environment}-etl-job"
  role_arn          = var.glue_role_arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 2880
  max_retries       = 1

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.code_bucket}/script.py"
  }

  default_arguments = {
    "--enable-auto-scaling"             = "true"
    "--enable-continous-cloudwatch-log" = "true"
    "--source-path"                     = "s3://${var.source_bucket}/"
    "--destination-path"                = "s3://${var.target_bucket}/"
    "--job-name"                        = "topdevs-${var.environment}-etl-job"
    "--enable-metrics"                  = "true"
  }
}