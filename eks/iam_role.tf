resource "aws_iam_role" "eks_cluster_role" {
  name                  = "${var.name}-eks-cluster-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "eks_node_group_role" {
  name                  = "${var.name}-eks-node-group-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "eks-pw-role" {
  name                  = "eks-pw-${var.environment}-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.oidc.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${aws_iam_openid_connect_provider.oidc.url}:sub": "system:serviceaccount:${kubernetes_namespace.pw.metadata.0.name}:${kubernetes_service_account.app-service-account.metadata.0.name}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "eks-banking-role" {
  name                  = "eks-banking-${var.environment}-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.oidc.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${aws_iam_openid_connect_provider.oidc.url}:sub": "system:serviceaccount:${kubernetes_namespace.banking.metadata.0.name}:${kubernetes_service_account.bank-service-account.metadata.0.name}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "external-dns-role" {
  name                  = "eks-external-dns-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.oidc.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${aws_iam_openid_connect_provider.oidc.url}:sub": "system:serviceaccount:external-dns:external-dns"
        }
      }
    }
  ]
}
POLICY
}

output "s3_iam_role_arn" {
  value = aws_iam_role.eks-banking-role.arn
}

output "pw_iam_role_arn" {
  value = aws_iam_role.eks-pw-role.arn
}