output "billing_alerts_sns_topic_arn" {
  description = "The ARN of the SNS topic for billing alerts"
  value       = module.alerts.sns_topic_arn
}

output "dashboard_url" {
  description = "The URL of the Cloud Cost Dashboard"
  value       = module.dashboard.website_url
}
