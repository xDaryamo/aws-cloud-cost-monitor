variable "bucket_name" {
  description = "Name of the S3 bucket for the website"
  type        = "string"
}

variable "domain_name" {
  description = "Custom domain name (e.g., aws-monitor-cost.dariomazza.net)"
  type        = "string"
}
