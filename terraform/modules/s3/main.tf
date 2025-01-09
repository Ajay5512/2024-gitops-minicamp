# modules/s3/main.tf
resource "aws_s3_bucket" "source_bucket" {
  bucket = "nexabrands-${var.environment}-${var.source_bucket}"
}

resource "aws_s3_object" "source_files" {
  for_each = var.source_files

  bucket = aws_s3_bucket.source_bucket.id
  key    = each.key
  source = each.value
}

resource "aws_s3_bucket" "target_bucket" {
  bucket = "nexabrands-${var.environment}-${var.target_bucket}"
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = "nexabrands-${var.environment}-${var.code_bucket}"
}

# Dynamic code files
resource "aws_s3_object" "code_files" {
  for_each = var.code_files

  bucket = aws_s3_bucket.code_bucket.id
  key    = each.key
  source = each.value
}

