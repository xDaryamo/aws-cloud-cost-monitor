terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.31"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "CloudCostCalculator"
      ManagedBy = "Terraform"
    }
  }
}

# Specific provider for Virginia (us-east-1) required for CloudFront SSL certificate
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "CloudCostCalculator"
      ManagedBy = "Terraform"
    }
  }
}