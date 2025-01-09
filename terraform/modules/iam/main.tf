# modules/iam/main.tf

# Glue Service Role
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

  tags = {
    Name = "topdevs-${var.environment}-glue-service-role"
  }
}

# Glue Service Policy
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
          "sns:Publish"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# Redshift Serverless Role
resource "aws_iam_role" "redshift-serverless-role" {
  name = "topdevs-${var.environment}-redshift-serverless-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })

  tags = {
    Name = "topdevs-${var.environment}-redshift-serverless-role"
  }
}

# Redshift S3 Full Access Policy
resource "aws_iam_role_policy" "redshift-s3-full-access-policy" {
  name = "topdevs-${var.environment}-redshift-serverless-role-s3-policy"
  role = aws_iam_role.redshift-serverless-role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = "*"
      }
    ]
  })
}

# Attach Redshift Full Access Policy
resource "aws_iam_role_policy_attachment" "attach-redshift" {
  role       = aws_iam_role.redshift-serverless-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess"
}
