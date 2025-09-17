# Configure Terraform and AWS Provider
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

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# 1. S3 Bucket for historical and sensitive customer information
resource "aws_s3_bucket" "customer_data" {
  bucket = "my-customer-data-bucket-2024"
  
  tags = {
    Purpose     = "Historical Customer Data"
    Sensitive   = "true"
    Environment = "production"
  }
}

# S3 Bucket Versioning (for data protection)
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

# 4. Lifecycle Configuration for Archiving
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

# 2. Create IAM Users: Bob and Dob
resource "aws_iam_user" "bob" {
  name = "bob"
  
  tags = {
    Role = "ReadOnly"
  }
}

resource "aws_iam_user" "dob" {
  name = "dob"
  
  tags = {
    Role = "UploadOnly"
  }
}

# IAM Policy for Bob (Read-Only Access)
resource "aws_iam_policy" "bob_s3_readonly" {
  name        = "BobS3ReadOnlyPolicy"
  description = "Read-only access to customer data bucket for Bob"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.customer_data.arn,
          "${aws_s3_bucket.customer_data.arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for Dob (Upload-Only Access)
resource "aws_iam_policy" "dob_s3_upload" {
  name        = "DobS3UploadPolicy"
  description = "Upload-only access to customer data bucket for Dob"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.customer_data.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.customer_data.arn
      }
    ]
  })
}

# Attach policies to users
resource "aws_iam_user_policy_attachment" "bob_policy_attachment" {
  user       = aws_iam_user.bob.name
  policy_arn = aws_iam_policy.bob_s3_readonly.arn
}

resource "aws_iam_user_policy_attachment" "dob_policy_attachment" {
  user       = aws_iam_user.dob.name
  policy_arn = aws_iam_policy.dob_s3_upload.arn
}

# 2. S3 Bucket Policy (Resource-based policy)
resource "aws_s3_bucket_policy" "customer_data_policy" {
  bucket = aws_s3_bucket.customer_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BobReadOnlyAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.bob.arn
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.customer_data.arn,
          "${aws_s3_bucket.customer_data.arn}/*"
        ]
      },
      {
        Sid    = "DobUploadOnlyAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.dob.arn
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.customer_data.arn}/*"
      },
      {
        Sid    = "CloudTrailAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.customer_data.arn,
          "${aws_s3_bucket.customer_data.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 3. CloudTrail for Auditing (Who has taken actions)
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "my-customer-data-bucket-2024-cloudtrail-logs"
}

resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "customer_data_trail" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_logs_policy]

  name           = "my-customer-data-bucket-2024-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.customer_data.arn}/*"]
    }

    data_resource {
      type   = "AWS::S3::Bucket"
      values = [aws_s3_bucket.customer_data.arn]
    }
  }

  tags = {
    Purpose = "Audit customer data bucket access"
  }
}
