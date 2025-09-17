# main.tf

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" 
}

# Create the S3 bucket
resource "aws_s3_bucket" "sensitive_data_bucket" {
  bucket = "dyn-media-interview-task"  
}

# Configure a lifecycle rule to transition objects to Glacier Deep Archive after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "glacier_transition" {
  bucket = aws_s3_bucket.sensitive_dyn-media-interview-task
  rule {
    id = "transition_to_glacier"
    status = "Enabled"
    
    # Add an empty filter block to apply the rule to all objects
    filter {}
    
    transition {
      days          = 90
      storage_class = "GLACIER_DEEP_ARCHIVE"
    }
  }
}
