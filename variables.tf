variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the archive S3 bucket (e.g. my-company-archive-2025)"
  type        = string
}

variable "role_name" {
  description = "Name of the existing IAM role to grant read-only access to the bucket"
  type        = string
}

variable "transition_days" {
  description = "Days before objects are transitioned to archival storage"
  type        = number
  default     = 30
}

variable "storage_class" {
  description = "Archive storage class for lifecycle transition (e.g. GLACIER, DEEP_ARCHIVE)"
  type        = string
  default     = "GLACIER"
}

variable "policy_name" {
  description = "Name for the IAM managed policy created"
  type        = string
  default     = "s3-archive-readonly-policy"
}

variable "cloudtrail_name" {
  description = "Name for the CloudTrail that will record S3 data events"
  type        = string
  default     = "s3-archive-cloudtrail"
}
