terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote S3 Backend leveraging native S3 Conditional Writes for state locking
  backend "s3" {
    bucket         = "avc09-bucket-terraform-state-17-jun-2026"
    key            = "dev/aws-iac-eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "CloudDevOps-Demo"
    }
  }
}