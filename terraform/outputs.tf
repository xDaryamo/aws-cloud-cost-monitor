output "billing_alerts_sns_topic_arn" {
  description = "The ARN of the SNS topic for billing alerts"
  value       = module.alerts.sns_topic_arn
}
