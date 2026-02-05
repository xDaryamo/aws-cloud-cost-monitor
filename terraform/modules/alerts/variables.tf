variable "notification_email" {
  description = "Email address for billing alerts"
  type        = string
}

variable "billing_threshold" {
  description = "The amount in USD to trigger the billing alarm"
  type        = number
}
