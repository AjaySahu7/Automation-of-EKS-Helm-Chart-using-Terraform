provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
    
  }
  debug = "true"
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  namespace        = "monitoring"
  create_namespace = true
  wait             = true
  reset_values     = true
  max_history      = 3
}

resource "helm_release" "externalsecret" {
  name             = "external-secrets"
  chart            = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  namespace        = "external-operator"
  create_namespace = true
  wait             = true
  reset_values     = true
  max_history      = 3
}

resource "helm_release" "kibana" {
  name             = "kibana"
  chart            = "kibana"
  repository       = "https://helm.elastic.co"
  namespace        = "dapr-monitoring"
  create_namespace = false
  wait             = true
  reset_values     = true
  max_history      = 3

  depends_on = [helm_release.elasticsearch]
}

resource "helm_release" "elasticsearch" {
  name             = "elastic"
  chart            = "elasticsearch"
  repository       = "https://helm.elastic.co"
  namespace        = "dapr-monitoring"
  create_namespace = true
  wait             = true
  reset_values     = true
  max_history      = 3

  set {
    name = "replicas"
    value = "1"
  }
}

resource "helm_release" "dapr" {
  name             = "dapr"
  chart            = "dapr"
  repository       = "https://dapr.github.io/helm-charts/"
  namespace        = "dapr-system"
  create_namespace = true
  wait             = true
  reset_values     = true
  max_history      = 3

  set {
    name = "global.logAsJson"
    value = "true"
  }
}

resource "helm_release" "external-dns" {
  name             = "external-dns"
  chart            = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  namespace        = "external-dns"
  create_namespace = true
  wait             = true
  reset_values     = true
  max_history      = 3

  set {
    name = "serviceAccount.name"
    value = "external-dns"
  }
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_id 
}