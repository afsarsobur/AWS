# main.tf

# Configure the AWS Provider
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

# Generate a unique bucket name
resource "random_pet" "bucket_name_prefix" {
  length = 2
}

# Create the S3 bucket for sensitive data
resource "aws_s3_bucket" "sensitive_data" {
  bucket = "sensitive-customer-data-${random_pet.bucket_name_prefix.id}"
  tags = {
    Name        = "Sensitive Customer Data"
    Environment = "production"
  }
}
