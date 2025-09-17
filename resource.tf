# Define the policy document for the bucket policy
data "aws_iam_policy_document" "bucket_policy_read_only" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.data_analyst.arn]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.sensitive_data.arn,
      "${aws_s3_bucket.sensitive_data.arn}/*"
    ]
  }
}

# Attach the policy to the S3 bucket
resource "aws_s3_bucket_policy" "read_only_bucket_policy" {
  bucket = aws_s3_bucket.sensitive_data.id
  policy = data.aws_iam_policy_document.bucket_policy_read_only.json
}
