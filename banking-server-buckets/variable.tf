variable "region" {}

variable "kyc_docs_bucket_name" {}

variable "locked_buckets" {
  type = map(object({
    retention_days = number
  }))
}

variable "s3_iam_role_arn" {}
