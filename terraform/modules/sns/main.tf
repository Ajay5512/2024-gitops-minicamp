# modules/sns/main.tf
resource "aws_sns_topic" "schema_changes" {
  name = "topdevs-${var.environment}-schema-changes"
}

resource "aws_sns_topic_policy" "schema_changes" {
  arn = aws_sns_topic.schema_changes.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGluePublish"
        Effect = "Allow"
        Principal = {
          AWS = var.glue_role_arn
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.schema_changes.arn
      }
    ]
  })
}



