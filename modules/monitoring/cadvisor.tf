# Creates a service account for cadvisor
resource "kubernetes_service_account" "cadvisor" {
    count = var.enable_monitoring && var.enable_cadvisor_metrics ? 1 : 0
    metadata {
      name = "cadvisor"
      namespace = kubernetes_namespace.prometheus[0].metadata[0].name
    }
}

# This creates a cluster role for cadvisor
resource "kubernetes_cluster_role" "cadvisor" {
    count = var.enable_monitoring && var.enable_cadvisor_metrics ? 1 : 0
  metadata {
    name = "cadvisor"
  }

  rule {
    api_groups = ["policy"]
    resources  = ["podsecuritypolicies"]
    verbs = ["use"]
    resource_names = ["cadvisor"]
  }
}
# This binds the cadvisor service account to the cadvisor cluster role
resource "kubernetes_cluster_role_binding" "cadvisor" {
  count = var.enable_monitoring && var.enable_cadvisor_metrics ? 1 : 0
  metadata {
    name = "cadvisor"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role.cadvisor[0].metadata[0].name
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.cadvisor[0].metadata[0].name
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }
}

# This creates a daemonset for cadvisor that runs on every node
resource "kubernetes_daemonset" "cadvisor" {
    count = var.enable_monitoring && var.enable_cadvisor_metrics ? 1 : 0
  metadata {
    name      = "cadvisor"
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        name = "cadvisor"
      }
    }

    template {
      metadata {
        labels = {
          name = "cadvisor"
          "prometheus.io/cadvisor" = "true"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.cadvisor[0].metadata[0].name

        container {
          name  = "cadvisor"
          image = "gcr.io/cadvisor/cadvisor:latest"

          volume_mount {
            name      = "rootfs"
            mount_path = "/rootfs"
            read_only  = true
          }

          volume_mount {
            name      = "var-run"
            mount_path = "/var/run"
            read_only  = true
          }

          volume_mount {
            name      = "sys"
            mount_path = "/sys"
            read_only  = true
          }

          volume_mount {
            name      = "docker"
            mount_path = "/var/lib/docker"
            read_only  = true
          }

          volume_mount {
            name      = "disk"
            mount_path = "/dev/disk"
            read_only  = true
          }

          port {
            name          = "http"
            container_port = 8080
            protocol      = "TCP"
          }

        }

        automount_service_account_token = false
        termination_grace_period_seconds = 30

        volume {
          name = "rootfs"

          host_path {
            path = "/"
          }
        }

        volume {
          name = "var-run"

          host_path {
            path = "/var/run"
          }
        }

        volume {
          name = "sys"

          host_path {
            path = "/sys"
          }
        }

        volume {
          name = "docker"

          host_path {
            path = "/var/lib/docker"
          }
        }

        volume {
          name = "disk"

          host_path {
            path = "/dev/disk"
          }
        }
      }
    }
  }
}

# This creates a service for cadvisor where it can be accessed by Prometheus
resource "kubernetes_service" "cadvisor" {
    count = var.enable_monitoring && var.enable_cadvisor_metrics ? 1 : 0
  metadata {
    name = "cadvisor"
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }

  spec {
    selector = {
      name = "cadvisor"
    }

    port {
      name = "http"
      port = 8080
      target_port = 8080
    }
  }
}




