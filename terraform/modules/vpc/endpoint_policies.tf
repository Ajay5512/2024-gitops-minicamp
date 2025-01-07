# modules/vpc/endpoint_policies.tf

resource "aws_vpc_endpoint_policy" "s3_endpoint_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSpecificBuckets"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.source_bucket}",
          "arn:aws:s3:::${var.source_bucket}/*",
          "arn:aws:s3:::${var.target_bucket}",
          "arn:aws:s3:::${var.target_bucket}/*",
          "arn:aws:s3:::${var.code_bucket}",
          "arn:aws:s3:::${var.code_bucket}/*"
        ]
      }
    ]
  })
}

# Add variables for bucket names
variable "source_bucket" {
  type        = string
  description = "Name of the source S3 bucket"
}

variable "target_bucket" {
  type        = string
  description = "Name of the target S3 bucket"
}

variable "code_bucket" {
  type        = string
  description = "Name of the code bucket"
}