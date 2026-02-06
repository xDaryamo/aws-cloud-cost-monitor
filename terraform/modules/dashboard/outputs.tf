output "website_url" {
  description = "The S3 Website URL (Restricted)"
  value       = aws_s3_bucket_website_configuration.dashboard_config.website_endpoint
}

output "cloudfront_url" {
  description = "The standard CloudFront URL"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "custom_domain_url" {
  description = "Your custom domain URL"
  value       = "https://${var.domain_name}"
}

output "bucket_id" {
  value = aws_s3_bucket.dashboard.id
}

output "cert_validation_options" {
  description = "DNS record details for SSL validation"
  value       = aws_acm_certificate.cert.domain_validation_options
}
