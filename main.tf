provider "aws" {
  region = "us-east-1"
}

# Use your existing role (replace with your role name)
data "aws_iam_role" "existing" {
  name = "BOB"
}

# S3 bucket
resource "aws_s3_bucket" "archive" {
  bucket = "my-simple-archive-bucket-2025565"
}

# IAM Policy (identity-based)
resource "aws_iam_policy" "readonly" {
  name = "s3-archive-readonly"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.archive.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.archive.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = data.aws_iam_role.existing.name
  policy_arn = aws_iam_policy.readonly.arn
}

# Bucket Policy (resource-based)
resource "aws_s3_bucket_policy" "archive_policy" {
  bucket = aws_s3_bucket.archive.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_iam_role.existing.arn
        }
        Action   = ["s3:ListBucket", "s3:GetObject"]
        Resource = [
          aws_s3_bucket.archive.arn,
          "${aws_s3_bucket.archive.arn}/*"
        ]
      }
    ]
  })
}
