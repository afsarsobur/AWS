# main.tf

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" 
}

# Create the S3 bucket
resource "aws_s3_bucket" "sensitive_data_bucket" {
  bucket = "dyn-media-interview-task"  
}
}

# Configure a lifecycle rule to transition objects to Glacier Deep Archive after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "glacier_transition" {
  bucket = aws_s3_bucket.sensitive_data_bucket.id
  rule {
    id = "transition_to_glacier"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "GLACIER_DEEP_ARCHIVE"
    }
  }
}
