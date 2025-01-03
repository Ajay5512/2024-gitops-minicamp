
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



# Update modules/glue/main.tf - Add schema change job
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
    "--enable-continuous-cloudwatch-log" = "true"
    "--catalog_id"                      = data.aws_caller_identity.current.account_id
    "--db_name"                         = aws_glue_catalog_database.database.name
    "--table_name"                      = aws_glue_crawler.crawler.name
    "--topic_arn"                       = var.sns_topic_arn
    "--job-name"                        = "topdevs-${var.environment}-schema-change-job"
    "--enable-metrics"                  = "true"
  }
}
