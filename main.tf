resource "aws_iam_policy" "s3_read_only" {
  name        = "s3-read-only-access-policy"
  description = "Provides read-only access to a specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::my-sensitive-data-bucket",
          "arn:aws:s3:::my-sensitive-data-bucket/*"
        ]
      },
    ]
  })
}
