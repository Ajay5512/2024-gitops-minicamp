# terraform/modules/lambda/main.tf
resource "aws_iam_role" "lambda_role" {
  name = "s3-copy-lambda-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "s3-copy-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::topdevs-${var.environment}-${var.source_bucket}",
          "arn:aws:s3:::topdevs-${var.environment}-${var.source_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::topdevs-${var.environment}-${var.target_bucket}",
          "arn:aws:s3:::topdevs-${var.environment}-${var.target_bucket}/*"
        ]
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/functions/s3_copy_function.py"
  output_path = "${path.module}/functions/s3_copy_function.zip"
}

resource "aws_lambda_function" "s3_copy_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "s3-copy-function-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "s3_copy_function.lambda_handler"
  runtime         = "python3.8"
  timeout         = 30

  environment {
    variables = {
      TARGET_BUCKET = "topdevs-${var.environment}-${var.target_bucket}"
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "topdevs-${var.environment}-${var.source_bucket}"

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_copy_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_copy_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::topdevs-${var.environment}-${var.source_bucket}"
}
