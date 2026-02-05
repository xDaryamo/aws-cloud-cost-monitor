output "website_url" {
  description = "The URL of the dashboard"
  value       = aws_s3_bucket_website_configuration.dashboard_config.website_endpoint
}

output "bucket_arn" {
  value = aws_s3_bucket.dashboard.arn
}

output "bucket_id" {
  value = aws_s3_bucket.dashboard.id
}