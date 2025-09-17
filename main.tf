resource "aws_iam_user" "readonly_user" {
  name = "s3-readonly-user"
  tags = {
    "Project" = "S3-Security-Task"
  }
}

resource "aws_iam_policy" "s3_readonly_policy" {
  name        = "s3-readonly-policy"
  description = "Provides read-only access to a specific S3 bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::my-secure-customer-data-bucket",
          "arn:aws:s3:::my-secure-customer-data-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_policy" {
  user       = aws_iam_user.readonly_user.name
  policy_arn = aws_iam_policy.s3_readonly_policy.arn
}

resource "aws_s3_bucket" "secure_customer_data" {
  bucket = "my-secure-customer-data-bucket"
  aws_s3_bucket_acl    = "private"
}
