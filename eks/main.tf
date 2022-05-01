provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.main.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.id
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
  policy_arn = aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCluserNLBPolicy" {
  policy_arn = aws_iam_policy.AmazonEKSClusterNLBPolicy.arn
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.name}-${var.environment}/cluster"
  retention_in_days = 30

  tags = {
    Name        = "${var.name}-${var.environment}-eks-cloudwatch-log-group"
    Environment = var.environment
  }
}

resource "aws_eks_cluster" "main" {
  name     = "${var.name}-${var.environment}"
  role_arn = aws_iam_role.eks_cluster_role.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = concat(var.public_subnets.*.id, var.private_subnets.*.id)
    endpoint_private_access = true
  }

  timeouts {
    delete = "30m"
  }

  depends_on = [
    #aws_cloudwatch_log_group.eks_cluster,
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy
  ]
}

# Fetch OIDC provider thumbprint for root CA

data "tls_certificate" "example" {
  url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.example.certificates.0.sha1_fingerprint]
  url             = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}


resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}


resource "aws_iam_role_policy_attachment" "app-secrets-policy-attach" {
  policy_arn = aws_iam_policy.app-secrets-policy.arn
  role       = aws_iam_role.eks-pw-role.name
}


resource "aws_iam_role_policy_attachment" "banking-secrets-policy-attach" {
  policy_arn = aws_iam_policy.banking-secrets-policy.arn
  role       = aws_iam_role.eks-banking-role.name
}

resource "aws_iam_role_policy_attachment" "banking-s3-policy-attach" {
  policy_arn = aws_iam_policy.banking-s3-policy.arn
  role       = aws_iam_role.eks-banking-role.name
}

resource "aws_iam_role_policy_attachment" "kms-policy-attach" {
  policy_arn = aws_iam_policy.kms_policy.arn
  role       = aws_iam_role.eks-banking-role.name
}

resource "aws_iam_role_policy_attachment" "AWSCloudMapFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudMapFullAccess"
  role       = aws_iam_role.external-dns-role.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "pw-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnets.*.id

  #Autoscaling worker node configuration

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
    
  }

  instance_types  = [var.workernode_instance_types]

  version = var.k8s_version

  tags = {
    Name        = "${var.name}-${var.environment}-eks-node-group"
    Environment = var.environment
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

data "template_file" "kubeconfig" {
  template = file("${path.module}/templates/kubeconfig.tpl")

  vars = {
    kubeconfig_name           = "eks_${aws_eks_cluster.main.name}"
    clustername               = aws_eks_cluster.main.name
    endpoint                  = data.aws_eks_cluster.cluster.endpoint
    cluster_auth_base64       = data.aws_eks_cluster.cluster.certificate_authority[0].data
  }
}

resource "local_file" "kubeconfig" {
  content  = data.template_file.kubeconfig.rendered
  filename = pathexpand("${var.kubeconfig_path}/config")
}

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
     command = <<EOT
      set -e
      echo 'Applying Auth ConfigMap with kubectl...'
      aws eks update-kubeconfig --name '${aws_eks_cluster.main.name}'  --region=${var.region}
    EOT
  }
}
output "kubectl_config" {
  description = "Path to new kubectl config file"
  value       = pathexpand("${var.kubeconfig_path}/config")
}

output "cluster_id" {
  description = "ID of the created cluster"
  value       = aws_eks_cluster.main.id
}
