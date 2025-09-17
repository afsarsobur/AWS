terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# get the existing role you mentioned you have already created
data "aws_iam_role" "existing" {
  name = var.role_name
}

# random suffix so log/cloudtrail buckets become unique
resource "random_id" "suffix" {
  byte_length = 4
}

#
# Primary archive bucket
#
resource "aws_s3_bucket" "archive_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256" # SSE-S3; change to KMS if you want KMS-managed keys
      }
    }
  }

  lifecycle_rule {
    id      = "archive-rule"
    enabled = true
    prefix  = "" # apply to all objects

    transition {
      days          = var.transition_days
      storage_class = var.storage_class
    }

    noncurrent_version_transition {
      days          = var.transition_days
      storage_class = var.storage_class
    }
  }
}

# block public access
resource "aws_s3_bucket_public_access_block" "archive_block_public" {
  bucket                  = aws_s3_bucket.archive_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#
# S3 server access log bucket (separate bucket to collect access logs)
#
resource "aws_s3_bucket" "log_bucket" {
  bucket        = "${var.bucket_name}-logs-${random_id.suffix.hex}"
  acl           = "log-delivery-write"
  force_destroy = true
}

resource "aws_s3_bucket_logging" "archive_logging" {
  bucket       = aws_s3_bucket.archive_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "access-logs/"
}

#
# CloudTrail + trail bucket to capture S3 data events (who did what)
#
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "${var.bucket_name}-ct-${random_id.suffix.hex}"
  acl           = "private"
  force_destroy = true
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid = "AWSCloudTrailAclCheck20150319"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_bucket.arn]
  }

  statement {
    sid = "AWSCloudTrailWrite20150319"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    # CloudTrail writes into AWSLogs/<account-id>/
    resources = ["${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

resource "aws_cloudtrail" "s3_trail" {
  name                          = var.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.archive_bucket.arn}/"]  # record S3 object-level events on this bucket
    }
  }
}

#
# Identity-based policy (IAM policy) -> attach to the existing role
# This is the identity policy you attach to the role the user/worker uses.
#
data "aws_iam_policy_document" "iam_read_policy" {
  statement {
    sid = "AllowListBucket"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.archive_bucket.arn
    ]
  }

  statement {
    sid = "AllowGetObject"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${aws_s3_bucket.archive_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "readonly_policy" {
  name   = var.policy_name
  policy = data.aws_iam_policy_document.iam_read_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  role       = data.aws_iam_role.existing.name
  policy_arn = aws_iam_policy.readonly_policy.arn
}

#
# Resource-based policy (bucket policy) -> allow the role principal read-only access
#
data "aws_iam_policy_document" "bucket_policy_doc" {
  statement {
    sid = "AllowRoleListBucket"
    effects = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.existing.arn]
    }
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.archive_bucket.arn
    ]
  }

  statement {
    sid = "AllowRoleGetObject"
    effects = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.existing.arn]
    }
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${aws_s3_bucket.archive_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "archive_bucket_policy" {
  bucket = aws_s3_bucket.archive_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy_doc.json
}
