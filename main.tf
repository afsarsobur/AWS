# main.tf

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create the S3 bucket
resource "aws_s3_bucket" "sensitive_data_bucket" {
  bucket = "dyn-media-int-taskkk"

# Configure a lifecycle rule
resource "aws_s3_bucket_lifecycle_configuration" "glacier_transition" {
  bucket = aws_s3_bucket.sensitive_data_bucket.id
  rule {
    id = "Acchivetoglachier" # The lifecycle rule name you requested
    status = "Enabled"
    filter {}
    transition {
      days          = 90
      storage_class = "GLACIER_DEEP_ARCHIVE"
    }
  }
}
