variable "bucket_name" {
  description = "Name of the S3 bucket for the dashboard"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "CloudCostCalculator"
}
