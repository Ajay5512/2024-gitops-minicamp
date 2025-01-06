# modules/redshift/main.tf

# Create an IAM Role for Redshift
resource "aws_iam_role" "redshift-serverless-role" {
  name = "${var.app_name}-redshift-serverless-role"
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
    Name = "${var.app_name}-redshift-serverless-role"
  }
}

# Create S3 access policy for Redshift
resource "aws_iam_role_policy" "redshift-s3-access-policy" {
  name = "${var.app_name}-redshift-s3-access-policy"
  role = aws_iam_role.redshift-serverless-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
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

# Update the Glue role policy to allow Redshift access
resource "aws_iam_role_policy" "glue-redshift-access" {
  name = "${var.app_name}-glue-redshift-access"
  role = var.glue_role_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:GetStatementResult",
          "redshift-data:DescribeStatement",
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters"
        ]
        Resource = [
          aws_redshiftserverless_workgroup.serverless.arn,
          aws_redshiftserverless_namespace.serverless.arn
        ]
      }
    ]
  })
}

# Create Redshift Serverless Namespace
resource "aws_redshiftserverless_namespace" "serverless" {
  namespace_name      = var.redshift_serverless_namespace_name
  db_name            = var.redshift_serverless_database_name
  admin_username     = var.redshift_serverless_admin_username
  admin_user_password = var.redshift_serverless_admin_password
  iam_roles          = [aws_iam_role.redshift-serverless-role.arn]

  tags = {
    Environment = var.environment
    Name        = var.redshift_serverless_namespace_name
  }
}

# Create Redshift Serverless Workgroup
resource "aws_redshiftserverless_workgroup" "serverless" {
  namespace_name     = aws_redshiftserverless_namespace.serverless.id
  workgroup_name     = "${var.app_name}-workgroup"
  base_capacity     = var.redshift_serverless_base_capacity
  security_group_ids = [aws_security_group.redshift-serverless-sg.id]
  subnet_ids        = var.subnet_ids
  publicly_accessible = false

  tags = {
    Environment = var.environment
    Name        = "${var.app_name}-workgroup"
  }
}

# Create Security Group for Redshift
resource "aws_security_group" "redshift-serverless-sg" {
  name        = "${var.app_name}-redshift-sg"
  description = "Security group for Redshift Serverless"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-redshift-sg"
  }
}