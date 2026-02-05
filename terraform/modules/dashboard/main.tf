resource "aws_s3_bucket" "dashboard" {
  bucket = var.bucket_name
  force_destroy = true # Allows deleting the bucket even if it contains files (useful for testing)
}

# Configure the bucket to host a static website
resource "aws_s3_bucket_website_configuration" "dashboard_config" {
  bucket = aws_s3_bucket.dashboard.id

  index_document {
    suffix = "index.html"
  }
}

# Disable public access blocking (necessary for a public static website)
resource "aws_s3_bucket_public_access_block" "dashboard_access" {
  bucket = aws_s3_bucket.dashboard.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Policy to allow public read access to the bucket
resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.dashboard.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.dashboard.arn}/*"
      },
    ]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.dashboard_access]
}

# --- IAM Role for Lambda ---
resource "aws_iam_role" "lambda_role" {
  name = "cost_reporter_lambda_role"

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

# --- IAM Policy for Cost Explorer, S3, and Logs ---
resource "aws_iam_role_policy" "lambda_policy" {
  name = "cost_reporter_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ce:GetCostAndUsage"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.dashboard.arn}/*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# --- Zip the Python code ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/cost_reporter.py"
  output_path = "${path.module}/lambda/cost_reporter.zip"
}

# --- Lambda Function ---
resource "aws_lambda_function" "cost_reporter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "cost_reporter_handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "cost_reporter.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.dashboard.id
    }
  }
}

# --- EventBridge Rule (The Timer) ---
resource "aws_cloudwatch_event_rule" "weekly_report_schedule" {
  name                = "weekly_cost_report_schedule"
  description         = "Triggers the cost reporter Lambda every Sunday at 00:00"
  schedule_expression = "cron(0 0 ? * SUN *)"
}

# --- EventBridge Target (Link Timer to Lambda) ---
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.weekly_report_schedule.name
  target_id = "cost_reporter_lambda"
  arn       = aws_lambda_function.cost_reporter.arn
}

# --- Upload the Dashboard UI ---
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.dashboard.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/index.html")
}

# --- Lambda Permission (Allow Timer to call Lambda) ---
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_report_schedule.arn
}
