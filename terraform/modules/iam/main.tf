
# modules/iam/main.tf
resource "aws_iam_role" "glue_service_role" {
  name = "topdevs-${var.environment}-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# resource "aws_iam_role_policy" "glue_service_policy" {
#   name = "topdevs-${var.environment}-glue-service-policy"
#   role = aws_iam_role.glue_service_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "glue:*",
#           "s3:GetBucketLocation",
#           "s3:ListBucket",
#           "s3:ListAllMyBuckets",
#           "s3:GetBucketAcl",
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject",
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "cloudwatch:PutMetricData"
#         ]
#         Resource = ["*"]
#       }
#     ]
#   })
# }



# Update modules/iam/main.tf - Add SNS permissions
resource "aws_iam_role_policy" "glue_service_policy" {
  name = "topdevs-${var.environment}-glue-service-policy"
  role = aws_iam_role.glue_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:*",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "s3:GetBucketAcl",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData",
          "sns:Publish"  # Add SNS publish permission
        ]
        Resource = ["*"]
      }
    ]
  })
}
