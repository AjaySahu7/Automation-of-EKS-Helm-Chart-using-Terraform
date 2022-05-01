resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
  name   = "AmazonEKSClusterCloudWatchMetricsPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "AmazonEKSClusterNLBPolicy" {
  name   = "AmazonEKSClusterNLBPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "elasticloadbalancing:*",
                "ec2:CreateSecurityGroup",
                "ec2:Describe*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "banking-secrets-policy" {
  name   = "banking-secrets-${var.environment}-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetRandomPassword",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
              "${var.docs_admin_user}",
              "${var.hybrid_api_dev_secret}",
              "${var.docs_main_user}"
              ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "app-secrets-policy" {
  name   = "app-secrets-${var.environment}-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetRandomPassword",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
              "${var.pw-dev-secret}",
              "${var.app_frontend_secrets}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "banking-s3-policy" {
  name   = "banking-s3-${var.environment}-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": [
            %{ for arn in var.locked_buckets }"${arn}",%{ endfor }
            "${var.kyc_docs_bucket}"]
            
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": ["s3:GetObject","s3:PutObject"],
            "Resource": [
            %{ for arn in var.locked_buckets }"${arn}/*",%{ endfor }
            "${var.kyc_docs_bucket}/*"]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "kms_policy" {
    name = "kms-${var.environment}-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableIAMRolePermissions",
            "Effect": "Allow",
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
EOF
}