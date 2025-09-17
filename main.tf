data "aws_iam_policy_document" "s3_read_only_policy_doc" {
  statement {
    sid    = "AllowS3ReadOnly"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::my-sensitive-data-bucket111",
      "arn:aws:s3:::my-sensitive-data-bucket111/*",
    ]
  }
}

resource "aws_iam_policy" "s3_read_only_policy" {
  name        = "S3ReadOnlyPolicy"
  description = "Allows read-only access to my-sensitive-data-bucket111"
  policy      = data.aws_iam_policy_document.s3_read_only_policy_doc.json
}
data "aws_iam_policy_document" "my_sensitive_data_bucket_policy_doc" {
  statement {
    sid    = "AllowUserReadOnly"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::123456789012:user/data-analyst"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::my-sensitive-data-bucket",
      "arn:aws:s3:::my-sensitive-data-bucket/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "my_sensitive_data_bucket_policy" {
  bucket = "my-sensitive-data-bucket"
  policy = data.aws_iam_policy_document.my_sensitive_data_bucket_policy_doc.json
}
