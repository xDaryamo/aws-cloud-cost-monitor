module "alerts" {
  source = "./modules/alerts"

  notification_email = var.notification_email
  billing_threshold  = var.billing_threshold
}