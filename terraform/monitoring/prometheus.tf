# This creates a namespace for prometheus
#
# Arguments
# - `count`: Checks if monitoring feature flag is enabled
# - `name`: The name of the RDS instance.
resource "kubernetes_namespace" "prometheus" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name = var.monitoring_namespace
  }
}

# This creates a cluster role for prometheus
#
# Arguments
# - `count`: Checks if monitoring feature flag is enabled
# - `name`: The name of the cluster role.
# - `rule`: The rules for the cluster role.
resource "kubernetes_cluster_role" "prometheus" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name = "prometheus-cluster-role"
  }


  rule {
    api_groups = [""]
    resources  = ["namespaces","services", "pods", "endpoints", "nodes", "nodes/metrics"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources = ["configmaps"]
    verbs = [ "get" ]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources = ["ingresses"]
    verbs = [ "get", "list", "watch" ]
  }

  rule {
    non_resource_urls = [ "/metrics" ]
    verbs = [ "get" ]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

# This creates a cluster role binding for prometheus
#
# Arguments
# - `count`: Checks if monitoring feature flag is enabled
# - `name`: The name of the cluster role binding.
# - `role_ref`: The role reference for the cluster role binding.
#    * `api_group`: The API group for the cluster role binding.
#    * `kind`: The kind for the cluster role binding.
#    * `name`: The name for the cluster role to bind.
# - `subject`: The subject for the cluster role binding.
#    * `kind`: The kind for the subject.
#    * `name`: The name for the subject.
#    * `namespace`: The namespace for the subject.
resource "kubernetes_cluster_role_binding" "prometheus_discoverer" {
  count = var.enable_monitoring ? 1 : 0
  depends_on = [ 
    kubernetes_cluster_role.prometheus,
    kubernetes_service_account.prometheus,
    kubernetes_namespace.prometheus
   ]
  metadata {
    name = "prometheus-discoverer"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role.prometheus[0].metadata[0].name
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.prometheus[0].metadata[0].name
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }
}
# This reades the prometheus config file
#
# Arguments
# - `count`: Checks if monitoring feature flag is enabled
# - `name`: The name of the config map.
# - `data`: The data for the config map.
#    * `prometheus.yml`: The prometheus config file.
# - `namespace`: The namespace for the config map.
resource "kubernetes_config_map" "prometheus-config"{
  count = var.enable_monitoring ? 1 : 0
  depends_on = [ 
    kubernetes_namespace.prometheus
   ]
    metadata {
        name = "prometheus-config"
        namespace = kubernetes_namespace.prometheus[0].metadata[0].name
    }

    # reads local config file
    data = {
        "prometheus.yml" = file("prometheus.yaml")
    }
}

# This creates a service account for prometheus
#
# Arguments
# - `count`: Checks if monitoring feature flag is enabled
# - `name`: The name of the service account.
# - `namespace`: The namespace for the service account.
resource "kubernetes_service_account" "prometheus" {
    count = var.enable_monitoring ? 1 : 0
  depends_on = [ 
    kubernetes_namespace.prometheus
   ]
  metadata {
    name = "prometheus"
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }
}


# This creates a prometheus deployment in the namespace created by the prometheus namespace resource
#
# Arguments
# - `count`: Checks if monitoring feature flag is enabled
# - `depends_on`: The resources that the deployment depends on.
#    * `kubernetes_namespace.prometheus`: The namespace for the deployment.
#    * `kubernetes_service_account.prometheus`: The service account for the deployment.
#    * `kubernetes_config_map.prometheus-config`: The config map for the deployment.
#    * `kubernetes_cluster_role.prometheus`: The cluster role for the deployment.
# - `metadata`: The metadata for the deployment.
#    * `name`: The name for the deployment.
#    * `labels`: The labels for the deployment.
#    * `namespace`: The namespace for the deployment.
# - `spec`: The spec for the deployment.
#    * `replicas`: The number of replicas for the deployment.
resource "kubernetes_deployment" "prometheus" {
    count = var.enable_monitoring ? 1 : 0
  depends_on = [ 
    kubernetes_namespace.prometheus,
    kubernetes_service_account.prometheus,
    kubernetes_config_map.prometheus-config,
    kubernetes_cluster_role.prometheus
   ]

  metadata {
    name = "prometheus"
    labels = {
      app = "prometheus"
    }
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "prometheus"
      }
    }
    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.prometheus[0].metadata[0].name
        automount_service_account_token = true
        container {
          name = "prometheus"
          image = "prom/prometheus:v2.45.0"
          args = []

          port {
            container_port = 9090
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/prometheus"
          }

          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.prometheus-config[0].metadata[0].name
          }
        }

        volume {
          name = "prometheus-storage"
          empty_dir {}
        }
      }
    }
  }
}

# This creates a service for prometheus to expose the prometheus deployment
#
# Arguments
# - `count`: Checks if monitoring feature flag is enabled
# - `spec`: The spec for the service.
resource "kubernetes_service" "prometheus" {
    count = var.enable_monitoring ? 1 : 0
    metadata {
        name = "prometheus-lb"
        namespace = kubernetes_namespace.prometheus[0].metadata[0].name
    }
    
    spec {
        selector = {
        app = "prometheus"
        }
    
        port {
        port        = 9090
        target_port = 9090
        }
    
        type = "NodePort"
    }
}

# This creates a service for prometheus to expose the prometheus deployment using an ALB
resource "kubernetes_ingress_v1" "prometheus" {
    count = var.enable_monitoring ? 1 : 0
  metadata {
    name = "prometheus"
    labels = {
      app = "prometheus"
    }
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name 

    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/group.name" = "outbound"
      "alb.ingress.kubernetes.io/group.order" = "1"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 9090}]"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = kubernetes_service.prometheus[0].metadata[0].name
              port {
                number = kubernetes_service.prometheus[0].spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}