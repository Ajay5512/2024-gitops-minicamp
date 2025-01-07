
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

resource "aws_iam_role" "redshift_serverless_role" {
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
}

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
          "s3:*",
          "logs:*",
          "cloudwatch:PutMetricData",
          "sns:Publish",
          "redshift-serverless:*",
          "redshift:*"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "redshift_s3_access" {
  name = "topdevs-${var.environment}-redshift-s3-access"
  role = aws_iam_role.redshift_serverless_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.source_bucket}",
          "arn:aws:s3:::${var.source_bucket}/*",
          "arn:aws:s3:::${var.target_bucket}",
          "arn:aws:s3:::${var.target_bucket}/*"
        ]
      }
    ]
  })
}
<<<<<<< HEAD
=======

# modules/iam/main.tf
resource "aws_iam_role" "redshift-serverless-role" {
  name = "nsw-properties-redshift-serverless-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "nsw-properties-redshift-serverless-role"
  }
}

resource "aws_iam_role_policy" "redshift-s3-full-access-policy" {
  name = "nsw-properties-redshift-serverless-role-s3-policy"
  role = aws_iam_role.redshift-serverless-role.id
  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Action": "s3:*",
       "Resource": "*"
      }
   ]
}
EOF
}

data "aws_iam_policy" "redshift-full-access-policy" {
  name = "AmazonRedshiftAllCommandsFullAccess"
}

resource "aws_iam_role_policy_attachment" "attach-s3" {
  role       = aws_iam_role.redshift-serverless-role.name
  policy_arn = data.aws_iam_policy.redshift-full-access-policy.arn
}

output "redshift_role_arn" {
  value = aws_iam_role.redshift-serverless-role.arn
}
>>>>>>> cd2c14e (uPDATE)
