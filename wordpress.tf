resource "kubernetes_deployment" "wordpress" {
  depends_on = [aws_db_instance.rds]


  metadata {
    name = "wordpress"
    labels = {
      app = "wordpress"
    }
    namespace = "default"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "wordpress"
      }
    }
    template {
      metadata {
        labels = {
          app                    = "wordpress"
          "prometheus.io/scrape" = "true"
        }
      }
      spec {
        container {
          image = "wordpress:6.2.1-apache"
          name  = "wordpress"
          env {
            name  = "WORDPRESS_DB_HOST"
            value = aws_db_instance.rds.endpoint
          }
          env {
            name  = "WORDPRESS_DB_USER"
            value = aws_db_instance.rds.username
          }
          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = aws_db_instance.rds.password
          }
          env {
            name  = "WORDPRESS_DB_DATABASE"
            value = aws_db_instance.rds.db_name
          }
          env {
            name  = "WP_DEBUG"
            value = true
          }
          env {
            name  = "WP_DEBUG_LOG"
            value = true
          }
          port {
            container_port = 80
          }
          port {
            container_port = 9090
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "wordpress" {
  metadata {
    name = "wordpress"
  }
  spec {
    selector = {
      app = kubernetes_deployment.wordpress.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 80
      protocol = "TCP"
    }


    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "wordpress" {
  metadata {
    name = "wordpress"
    labels = {
      app = "wordpress"
    }

    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/group.name" = "outbound"
      "alb.ingress.kubernetes.io/group.order" = "2"
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
              name = kubernetes_service.wordpress.metadata[0].name
              port {
                number = kubernetes_service.wordpress.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}
