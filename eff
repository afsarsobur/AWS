# Configure S3 lifecycle policy to transition objects to Glacier
resource "aws_s3_bucket_lifecycle_configuration" "glacier_transition" {
  bucket = aws_s3_bucket.sensitive_data.id
  rule {
    id = "glacier-archive"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER_FLEXIBLE_RETRIEVAL"
    }

    # Optional: Clean up older noncurrent versions after 90 days
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER_FLEXIBLE_RETRIEVAL"
    }
  }
}
