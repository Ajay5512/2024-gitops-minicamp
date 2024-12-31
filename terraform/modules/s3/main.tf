resource "aws_s3_bucket" "enterprise_raw_data" {
  bucket        = "enterprise-raw-data-${var.aws_region}"
  force_destroy = true
  tags          = var.common_tags
}

resource "aws_s3_bucket_object" "org_master_data" {
  bucket = aws_s3_bucket.enterprise_raw_data.bucket
  key    = "master/organizations.csv"
  source = "D:/Terraform_Tutorial/glue_job_S3_read_write/data_file/organizations.csv"
}

resource "aws_s3_bucket" "enterprise_processed_data" {
  bucket        = "enterprise-processed-data-${var.aws_region}"
  force_destroy = true
  tags          = var.common_tags
}

resource "aws_s3_bucket" "enterprise_etl_scripts" {
  bucket        = "enterprise-etl-scripts-${var.aws_region}"
  force_destroy = true
  tags          = var.common_tags
}

resource "aws_s3_bucket_object" "org_etl_script" {
  bucket = aws_s3_bucket.enterprise_etl_scripts.bucket
  key    = "glue/org_data_processor.py"
  source = "D:/Terraform_Tutorial/glue_job_S3_read_write/data_file/script.py"
}