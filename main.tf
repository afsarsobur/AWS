provider "aws" {
  region = "us-east-1"  # specify your preferred region
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name-12345"  # bucket names must be globally unique
  acl    = "private"
}
