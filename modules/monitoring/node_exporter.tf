
# Create a Kubernetes DaemonSet for the node exporter
resource "kubernetes_daemonset" "node_exporter" {
    count = var.enable_monitoring && var.enable_node_monitoring ? 1 : 0
  metadata {
    name = "node-exporter"
    labels = {
      app = "node-exporter"
    }
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = "node-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "node-exporter"
          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        container {
          name = "node-exporter"
          image = "prom/node-exporter:v1.2.2"
          args = [
            "--web.listen-address=:9100",
            "--path.procfs=/host/proc",
            "--path.sysfs=/host/sys",
            "--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|run|var/lib/docker/.+)($|/)",
          ]
          port {
            container_port = 9100
          }
          volume_mount {
            name = "proc"
            mount_path = "/host/proc"
            read_only = true
          }
          volume_mount {
            name = "sys"
            mount_path = "/host/sys"
            read_only = true
          }
        }

        volume {
          name = "proc"
          host_path {
            path = "/proc"
          }
        }
        volume {
          name = "sys"
          host_path {
            path = "/sys"
          }
        }
      }
    }
  }
}





# Expose the node exporter metrics endpoint using a Kubernetes service
resource "kubernetes_service" "node_exporter" {
    count = var.enable_monitoring && var.enable_node_monitoring ? 1 : 0
  metadata {
    name = "node-exporter"
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
    annotations = {
      
    }
  }

  spec {
    selector = {
      app = "node-exporter"
    }

    port {
      name = "metrics"
      port = 9100
      target_port = 9100
    }
  }
}