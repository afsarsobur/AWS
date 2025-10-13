resource "aws_s3_bucket" "bucket" {
  bucket = "my-terraform-bucket-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
