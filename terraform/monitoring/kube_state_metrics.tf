# This creates a serivce account for the kube-state-metrics deployment
resource "kubernetes_service_account" "kube_state_metrics" {
    count = var.enable_monitoring && var.enable_kube_state_metrics ? 1 : 0
  depends_on = [ 
    kubernetes_namespace.prometheus
   ]

  metadata {
    name = "kube-state-metrics"
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }
}

# This creates a cluster role for the kube-state-metrics deployment
resource "kubernetes_cluster_role" "kube_state_metrics" {
    count = var.enable_monitoring && var.enable_kube_state_metrics ? 1 : 0
  metadata {
    name = "kube-state-metrics"
    labels = {
      "app.kubernetes.io/component" = "exporter"
      "app.kubernetes.io/name" = "kube-state-metrics"
      "app.kubernetes.io/version" = "2.10.0"
    }
  }

  rule {
    api_groups = [""]
    resources = [
      "configmaps",
      "secrets",
      "nodes",
      "pods",
      "services",
      "serviceaccounts",
      "resourcequotas",
      "replicationcontrollers",
      "limitranges",
      "persistentvolumeclaims",
      "persistentvolumes",
      "namespaces",
      "endpoints",
    ]
    verbs = ["list", "watch"]
  }
    rule {
    api_groups = ["apps"]
    resources = [
      "statefulsets",
      "daemonsets",
      "deployments",
      "replicasets",
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources = ["cronjobs", "jobs"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources = ["horizontalpodautoscalers"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["authentication.k8s.io"]
    resources = ["tokenreviews"]
    verbs = ["create"]
  }
   rule {
    api_groups = ["authorization.k8s.io"]
    resources = ["subjectaccessreviews"]
    verbs = ["create"]
  }

  rule {
    api_groups = ["policy"]
    resources = ["poddisruptionbudgets"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["certificates.k8s.io"]
    resources = ["certificatesigningrequests"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources = ["endpointslices"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources = ["storageclasses", "volumeattachments"]
    verbs = ["list", "watch"]
  }
    rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources = [
      "mutatingwebhookconfigurations",
      "validatingwebhookconfigurations",
    ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources = ["networkpolicies", "ingressclasses", "ingresses"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources = ["leases"]
    verbs = ["list", "watch"]
  }
  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources = [
      "clusterrolebindings",
      "clusterroles",
      "rolebindings",
      "roles",
    ]
    verbs = ["list", "watch"]
  }
}

# This binds the kube-state-metrics service account to the kube-state-metrics cluster role
resource "kubernetes_cluster_role_binding" "kube_state_metrics" {
    count = var.enable_monitoring && var.enable_kube_state_metrics ? 1 : 0
    metadata {
    name = "kube-state-metrics"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role.kube_state_metrics[0].metadata[0].name
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.kube_state_metrics[0].metadata[0].name
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
  }
}


# This deploys the kube-state-metrics monitoring agent
resource "kubernetes_deployment" "kube_state_metrics" {
    count = var.enable_monitoring && var.enable_kube_state_metrics ? 1 : 0
  metadata {
    name = "kube-state-metrics"
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name
    labels = {
      "app.kubernetes.io/component" = "exporter",
      "app.kubernetes.io/name" = "kube-state-metrics",
      "app.kubernetes.io/version" = "2.10.0",
      "prometheus.io/cluster" = "true"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "kube-state-metrics"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/component" = "exporter",
          "app.kubernetes.io/name" = "kube-state-metrics",
          "app.kubernetes.io/version" = "2.10.0",
          "prometheus.io/cluster" = "true"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.kube_state_metrics[0].metadata[0].name
        container {
          image = "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.10.0"
          name = "kube-state-metrics"
          port {
            container_port = 8080
            name = "http-metrics"
          }

          port {
            container_port = 8081
            name = "telemetry"
          }
        }
      }
    }
    
  } 
}

# This creates a service for the kube-state-metrics monitoring agent where it can be accessed by Prometheus
resource "kubernetes_service" "kube_state_metrics" {
    count = var.enable_monitoring && var.enable_kube_state_metrics ? 1 : 0
    metadata {
      name = "kube-state-metrics"
      namespace = kubernetes_namespace.prometheus[0].metadata[0].name
      labels = {
        "app.kubernetes.io/component" = "exporter",
        "app.kubernetes.io/name" = "kube-state-metrics",
        "app.kubernetes.io/version" = "2.10.0",
      }
    }

    spec {
      cluster_ip = "None"
      port {
        name = "http-metrics"
        port = 8080
        target_port = 8080
      }

      port {
        name = "telemetry"
        port = 8081
        target_port = 8081
      }
  selector = {
    "app.kubernetes.io/name" = "kube-state-metrics"
  }   
}
}