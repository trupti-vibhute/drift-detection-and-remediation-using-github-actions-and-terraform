# Bootstrap: S3 bucket that stores the remote Terraform state for the main project
# This folder uses LOCAL state on purpose - the bucket can't store its own state before it exists
# Run this once, before initializing the main project

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "Terraform-Drift-Detection"
      Purpose   = "Terraform-State-Backend"
      ManagedBy = "Terraform"
    }
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name

  # Losing this bucket means losing track of all deployed infrastructure
  lifecycle {
    prevent_destroy = true
  }
}

# Keep every version of the state file so we can roll back if it gets corrupted
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# State can contain sensitive values, so encrypt it at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# The state bucket must never be public
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
