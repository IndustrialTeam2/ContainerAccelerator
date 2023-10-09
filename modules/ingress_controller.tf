# This file is used to deploy the AWS Load Balancer Controller to the EKS cluster.


# This will create an IAM role for the AWS Load Balancer Controller.
# The IAM role will be annotated with the ARN of the OIDC provider created in the eks module to associate the IAM role with the OIDC provider.
#
# Arguments:
# - `role_name`: The name of the IAM role.
# - `attach_load_balancer_controller_policy`: Whether to attach the AWSLoadBalancerControllerIAMPolicy to the IAM role.
# - `oidc_providers`: A map of OIDC provider ARNs to a list of namespaces and service accounts to associate with the IAM role.
#     * `provider_arn`: The ARN of the OIDC provider.
#     * `namespace_service_accounts`: A list of namespaces and service accounts to associate with the IAM role.
module "lb_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "alb-ingress-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# This will create a Kubernetes service account for the AWS Load Balancer Controller.
#
# Arguments:
# - `name`: The name of the service account.
# - `namespace`: The namespace in which to create the service account.
# - `labels`: A map of labels to associate with the service account.
# - `annotations`: A map of annotations to associate with the service account.
resource "kubernetes_service_account" "alb_ingress_controller" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
        "app.kubernetes.io/name"= "aws-load-balancer-controller"
        "app.kubernetes.io/component"= "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
  
}

# This will create a Helm release of the AWS Load Balancer Controller.
#
# Arguments:
# - `name`: The name of the Helm release.
# - `repository`: The OCI registry URL for the AWS Load Balancer Controller container image.
# - `chart`: The name of the Helm chart to install.
# - `namespace`: The namespace in which to install the Helm release.
# - `depends_on`: A list of dependencies for the Helm release.
# - `set`: A list of key-value pairs to set as values for the Helm chart.
#     * `region`: The AWS region in which the EKS cluster is deployed.
#     * `vpcId`: The ID of the VPC in which the EKS cluster is deployed.
#     * `image.repository`: The OCI registry URL for the AWS Load Balancer Controller container image.
#     * `serviceAccount.create`: Whether to create the Kubernetes service account.
#     * `serviceAccount.name`: The name of the Kubernetes service account. (only used if `serviceAccount.create` is `false`)
#     * `clusterName`: The name of the EKS cluster.
resource "helm_release" "lb" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.alb_ingress_controller,
  ]

  set {
    name  = "region"
    value = "us-east-1"
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.eu-west-2.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb_ingress_controller.metadata[0].name
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
}



