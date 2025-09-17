# Define an IAM user
resource "aws_iam_user" "data_analyst" {
  name = "data-analyst-user"
}

# Define the policy document for read-only access
data "aws_iam_policy_document" "read_only_s3_policy" {
  statement {
    effect = "Allow"
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

# Create the IAM policy resource
resource "aws_iam_policy" "s3_read_only" {
  name        = "S3ReadOnlyAccessForSensitiveData"
  description = "Grants read-only access to the sensitive data S3 bucket"
  policy      = data.aws_iam_policy_document.read_only_s3_policy.json
}

# Attach the policy to the IAM user
resource "aws_iam_policy_attachment" "s3_read_only_attachment" {
  name       = "s3-read-only-attachment"
  users      = [aws_iam_user.data_analyst.name]
  policy_arn = aws_iam_policy.s3_read_only.arn
}
