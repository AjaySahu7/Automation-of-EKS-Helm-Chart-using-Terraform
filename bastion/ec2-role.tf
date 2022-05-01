resource "aws_iam_policy" "eks" {
  name = var.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "eks:*",
                "iam:*",
                "cloudformation:*"
            ]
        }
  ]
}
EOF
}

resource "aws_iam_role" "ec2-access" {
  name               = "ec2-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role-attach" {
  role       = aws_iam_role.ec2-access.name
  policy_arn = aws_iam_policy.eks.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
   name  = "ec2_profile"
   role = aws_iam_role.ec2-access.name
}
