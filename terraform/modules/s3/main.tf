# modules/s3/main.tf

resource "aws_s3_bucket" "source_bucket" {
  bucket = "topdevs-${var.environment}-${var.source_bucket}"
}

resource "aws_s3_object" "organizations_file" {
  bucket = aws_s3_bucket.source_bucket.id
  key    = "organizations.csv"
  source = var.organizations_csv_path
}

resource "aws_s3_bucket" "target_bucket" {
  bucket = "topdevs-${var.environment}-${var.target_bucket}"
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = "topdevs-${var.environment}-${var.code_bucket}"
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.code_bucket.id
  key    = "script.py"
  source = var.script_path
}

resource "aws_s3_object" "schema_change_script" {
  bucket = aws_s3_bucket.code_bucket.id
  key    = "schema_change.py"
  source = var.schema_change_script_path
}