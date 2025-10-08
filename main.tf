terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "customer_data" {
  bucket = "dyn-media-interview-task123"
  
  tags = {
    Purpose     = "Historical Customer Data"
    Sensitive   = "true"
    Environment = "interview-task"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "customer_data_versioning" {
  bucket = aws_s3_bucket.customer_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "customer_data_encryption" {
  bucket = aws_s3_bucket.customer_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "customer_data_pab" {
  bucket = aws_s3_bucket.customer_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "customer_data_lifecycle" {
  bucket = aws_s3_bucket.customer_data.id
  rule {
    id     = "archive_old_data"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

# Output
output "bucket_name" {
  value = aws_s3_bucket.customer_data.id
}
