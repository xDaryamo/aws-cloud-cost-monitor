# IAM role and policies for Lambda execution
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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "cost_reporter_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ce:GetCostAndUsage"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["s3:PutObject"]
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

# Lambda function to generate the cost report
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/cost_reporter.py"
  output_path = "${path.module}/lambda/cost_reporter.zip"
}

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

# EventBridge rule to trigger Lambda on a schedule
resource "aws_cloudwatch_event_rule" "weekly_report_schedule" {
  name                = "weekly_cost_report_schedule"
  description         = "Trigger Lambda every Sunday at midnight"
  schedule_expression = "cron(0 0 ? * SUN *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.weekly_report_schedule.name
  target_id = "cost_reporter_lambda"
  arn       = aws_lambda_function.cost_reporter.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_report_schedule.arn
}