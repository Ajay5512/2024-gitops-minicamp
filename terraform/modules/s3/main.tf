resource "aws_s3_bucket" "source_data" {
  bucket = "${var.project}-${var.environment}-source-data"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project
    Managed_by  = "terraform"
  }
}

resource "aws_s3_bucket" "target_data" {
  bucket = "${var.project}-${var.environment}-target-data"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project
    Managed_by  = "terraform"
  }
}

resource "aws_s3_bucket" "code" {
  bucket = "${var.project}-${var.environment}-glue-code"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project
    Managed_by  = "terraform"
  }
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.code.id
  key    = "scripts/org_data_processor.py"
  source = "${path.root}/scripts/glue/org_data_processor.py"

  etag = filemd5("${path.root}/scripts/glue/org_data_processor.py")
}