resource "kubernetes_namespace" "pw" {
  metadata {
    name = "pw-${var.environment}"
  }
}

resource "kubernetes_namespace" "banking" {
  metadata {
    name = "banking-${var.environment}"
  }
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "kubernetes_service_account" "app-service-account" {
  metadata {
    name = "pw-${var.environment}-service-account"
    annotations = {
      "eks.amazonaws.com/role-arn": "arn:aws:iam::${var.accountid}:role/eks-pw-${var.environment}-role"
    }
    namespace = kubernetes_namespace.pw.metadata.0.name
  }
  depends_on = [ kubernetes_namespace.pw  ]
}

resource "kubernetes_service_account" "bank-service-account" {
  metadata {
    name = "banking-${var.environment}-service-account"
    annotations = {
      "eks.amazonaws.com/role-arn": "arn:aws:iam::${var.accountid}:role/eks-banking-${var.environment}-role"
    }
    namespace = kubernetes_namespace.banking.metadata.0.name
  }
  depends_on = [ kubernetes_namespace.banking  ]
}

resource "kubernetes_service_account" "external-dns-service-account" {
  metadata {
    name = "external-dns"
    annotations = {
      "eks.amazonaws.com/role-arn": "arn:aws:iam::${var.accountid}:role/eks-external-dns-role"
    }
    namespace = "external-dns"
  }
}

resource "kubernetes_config_map" "fluentd" {
  metadata {
    name = "fluentd-config"
    namespace = "kube-system"
  }

  data = {
    "fluent.conf" = "${file("${path.module}/fluent.conf")}"
  }
}

resource "kubernetes_service_account" "fluentd" {
  metadata {
    name = "fluentd"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "fluentd" {
  metadata {
    name = "fluentd"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluentd" {
  metadata {
    name = "fluentd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "fluentd"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "fluentd"
    namespace = "kube-system"
  }
}

resource "kubernetes_daemonset" "fluentd" {
  metadata {
    name      = "fluentd"
    namespace = "kube-system"
    labels = {
      k8s-app = "fluentd-logging"
      version = "v1"
    }
  }

  spec {
    selector {
      match_labels = {
        k8s-app = "fluentd-logging"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = "fluentd-logging"
          version = "v1"
        }
      }

      spec {
        service_account_name = "fluentd"
        toleration {
          key =  "node-role.kubernetes.io/master"
          effect =  "NoSchedule"
        }
        container {
          image = "fluent/fluentd-kubernetes-daemonset:v1.9.2-debian-elasticsearch7-1.0"
          name  = "fluentd"
          env {
            name  = "FLUENT_ELASTICSEARCH_HOST"
            value = "elasticsearch-master.dapr-monitoring"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_PORT"
            value = "9200"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_SCHEME"
            value = "http"
          }
          env {
            name  = "FLUENT_UID"
            value = "0"
          }
          resources {
            limits = {
              memory = "200Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "200Mi"
            }
          }
          volume_mount {
            name = "varlog"
            mount_path = "/var/log"
          }
          volume_mount {
            name = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = "true"
          }
          volume_mount {
            name = "fluentd-config"
            mount_path = "/fluentd/etc"
          }
        }
        volume {
          name = "varlog"
            host_path {
              path = "/var/log"
            }
        }
        volume {
          name = "varlibdockercontainers"
            host_path {
              path = "/var/lib/docker/containers"
            }
        }
        volume {
          name = "fluentd-config"
            config_map {
              name = "fluentd-config"
            }
        }
      }
    }
  }
}

output "app_namespace" {
  value = kubernetes_namespace.pw.metadata.0.name
}

output "bank_namespace" {
  value = kubernetes_namespace.banking.metadata.0.name
}

output "app-service-account" {
  value = kubernetes_service_account.app-service-account.metadata.0.name
}

output "bank-service-account" {
  value = kubernetes_service_account.bank-service-account.metadata.0.name
}