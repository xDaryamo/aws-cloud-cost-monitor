variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "notification_email" {
  description = "Email address for billing alerts"
  type        = string
}

variable "billing_threshold" {
  description = "The amount in USD to trigger the billing alarm"
  type        = number
  default     = 10
}

variable "dashboard_bucket_name" {
  description = "Unique name for the S3 bucket hosting the dashboard"
  type        = string
}
