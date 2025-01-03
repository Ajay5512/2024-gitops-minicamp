
# modules/s3/main.tf
resource "aws_s3_bucket" "source_bucket" {
  bucket = "topdevs-${var.environment}-${var.source_bucket}"
}

resource "aws_s3_bucket" "target_bucket" {
  bucket = "topdevs-${var.environment}-${var.target_bucket}"
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = "topdevs-${var.environment}-${var.code_bucket}"
}

resource "aws_s3_bucket_object" "glue_script" {
  bucket = aws_s3_bucket.code_bucket.id
  key    = "script.py"
  source = var.script_path
}