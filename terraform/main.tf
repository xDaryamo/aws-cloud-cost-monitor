module "alerts" {
  source = "./modules/alerts"

  notification_email = var.notification_email
  billing_threshold  = var.billing_threshold
}

module "dashboard" {

  source = "./modules/dashboard"



  bucket_name = var.dashboard_bucket_name

  domain_name = "aws-monitor-cost.dariomazza.net"

  providers = {

    aws.virginia = aws.virginia

  }

}


