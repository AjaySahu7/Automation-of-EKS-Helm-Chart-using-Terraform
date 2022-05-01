resource "aws_kms_key" "pw_kms_key" {
  description         = "My KMS Keys for Data Encryption"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  is_enabled               = true

  tags = {
    Name = "pw_kms_key"
  }
}

output "key_id" {
  value = aws_kms_key.pw_kms_key.key_id
}

resource "aws_s3_bucket" "kyc_docs_bucket" {
  bucket = var.kyc_docs_bucket_name
}

resource "aws_s3_bucket_public_access_block" "s3_private" {
  bucket = aws_s3_bucket.kyc_docs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "locked_buckets" {
  for_each = var.locked_buckets
  bucket = each.key
  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_private_lock" {
  for_each = var.locked_buckets
  bucket = each.key
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object_lock_configuration" "object" {
  for_each = var.locked_buckets
  bucket = each.key
  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = each.value.retention_days
    }
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "encyption" {
  for_each = var.locked_buckets
  bucket = each.key

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.pw_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kyc_docs_encyption" {
  bucket = var.kyc_docs_bucket_name

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.pw_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_iam_role" {
  bucket = aws_s3_bucket.kyc_docs_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.s3_iam_role_arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.kyc_docs_bucket.arn,
      "${aws_s3_bucket.kyc_docs_bucket.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow-access" {
  for_each = aws_s3_bucket.locked_buckets
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.s3_iam_role_arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
         each.value.arn,
      "${each.value.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access" {
  for_each = {for idx, bucket in aws_s3_bucket.locked_buckets: idx => bucket}
  bucket = each.value.id
  policy = data.aws_iam_policy_document.allow-access[each.key].json
}

output "locked_buckets" {
   value =  values(aws_s3_bucket.locked_buckets)[*].arn
}

output "kyc_docs_bucket" {
  value = aws_s3_bucket.kyc_docs_bucket.arn
}