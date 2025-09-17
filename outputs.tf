output "archive_bucket_name" {
  value = aws_s3_bucket.archive_bucket.bucket
}

output "archive_bucket_arn" {
  value = aws_s3_bucket.archive_bucket.arn
}

output "readonly_policy_arn" {
  value = aws_iam_policy.readonly_policy.arn
}

output "cloudtrail_name" {
  value = aws_cloudtrail.s3_trail.name
}
