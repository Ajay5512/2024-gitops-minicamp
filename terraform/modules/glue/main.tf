data "aws_caller_identity" "current" {}

resource "aws_glue_catalog_database" "database" {
  name        = "topdevs-${var.environment}-report"
  description = "Database for ${var.environment} environment organization reports"
}

resource "aws_glue_catalog_database" "external" {
  name        = "nexabrands_dbt"
  description = "External database for Redshift Spectrum tables"
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

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
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
    script_location = "s3://${var.code_bucket}/scripts/script.py"
  }

  default_arguments = {
    "--enable-auto-scaling"              = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--source-path"                      = "s3://${var.source_bucket}/"
    "--destination-path"                 = "s3://${var.target_bucket}/"
    "--job-name"                         = "topdevs-${var.environment}-etl-job"
    "--enable-metrics"                   = "true"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = {
    Environment = var.environment
    Service     = "glue"
  }
}


# Variables
variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "glue_role_arn" {
  description = "The ARN of the IAM role for Glue"
  type        = string
}

variable "code_bucket" {
  description = "The S3 bucket where the Glue scripts are stored"
  type        = string
}

variable "source_bucket" {
  description = "The S3 bucket for source data"
  type        = string
}

variable "target_bucket" {
  description = "The S3 bucket for processed data"
  type        = string
}

# Glue Jobs
locals {
  jobs = {
    products_etl        = "products_etl"
    orders              = "orders_etl"
    order_lines         = "order_lines_etl"
    order_fulfillment   = "order_fulfillment_etl"
    dates               = "dates_etl"
    customers           = "customers_etl"
    customer_targets    = "customer_targets_etl"
  }
}

resource "aws_glue_job" "etl_jobs" {
  for_each = local.jobs

  name              = "topdevs-${var.environment}-${each.value}-job"
  role_arn          = var.glue_role_arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 2880
  max_retries       = 1

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.code_bucket}/scripts/${each.value}.py"
  }

  default_arguments = {
    "--enable-auto-scaling"              = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--source-path"                      = "s3://${var.source_bucket}/"
    "--destination-path"                 = "s3://${var.target_bucket}/"
    "--job-name"                         = "topdevs-${var.environment}-${each.value}-job"
    "--enable-metrics"                   = "true"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = {
    Environment = var.environment
    Service     = "glue"
  }
}