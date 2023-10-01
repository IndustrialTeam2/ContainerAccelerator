<<<<<<< Updated upstream
# # # Kubernetes provider
# # # https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# # # To learn how to schedule deployments and services using the provider, go here: ttps://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes.

# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     # This requires the awscli to be installed locally where Terraform is executed
#     args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#   }

# }



# resource "kubernetes_deployment" "wordpress" {
#   depends_on = [aws_db_instance.rds]


#   metadata {
#     name = "wordpress"
#     labels = {
#       app = "wordpress"
#     }
#     namespace = "default"
#   }

#   spec {
#     replicas = 1
#     selector {
#       match_labels = {
#         app = "wordpress"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = "wordpress"
#           "prometheus.io/scrape" = "true"
#         }
#       }
#       spec {
#         container {
#           image = "wordpress:6.2.1-apache"
#           name  = "wordpress"
#           env {
#             name  = "WORDPRESS_DB_HOST"
#             value = aws_db_instance.rds.endpoint
#           }
#           env {
#             name  = "WORDPRESS_DB_USER"
#             value = aws_db_instance.rds.username
#           }
#           env {
#             name  = "WORDPRESS_DB_PASSWORD"
#             value = aws_db_instance.rds.password
#           }
#           env {
#             name  = "WORDPRESS_DB_DATABASE"
#             value = aws_db_instance.rds.db_name
#           }
#           env {
#             name = "WP_DEBUG"
#             value = true
#           }
#           env {
#             name = "WP_DEBUG_LOG"
#             value = true
#           }
#           port {
#             container_port = 80
#           }
#         }
#       }
#     }
#   }
# }


# resource "kubernetes_service" "wordpress" {
#   metadata {
#     name = "wordpress"
#   }
#   spec {
#     selector = {
#       app = kubernetes_deployment.wordpress.spec.0.template.0.metadata[0].labels.app
#     }
#     port {
#       port        = 80
#       target_port = 80
#     }


#     type = "LoadBalancer"
#   }
# }





# # Create a local variable for the load balancer name.
# locals {
#   lb_name = split("-", split(".", kubernetes_service.wordpress.status.0.load_balancer.0.ingress.0.hostname).0).0
# }

# # Read information about the load balancer using the AWS provider.
# data "aws_elb" "load_balancer_name" {
#   name = local.lb_name
# }

# output "load_balancer_name" {
#   value = local.lb_name
# }

# output "load_balancer_hostname" {
#   value = kubernetes_service.wordpress.status.0.load_balancer.0.ingress.0.hostname
# }

# output "load_balancer_info" {
#   value = data.aws_elb.load_balancer_name
# }

=======
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
>>>>>>> Stashed changes
