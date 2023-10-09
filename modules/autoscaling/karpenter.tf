# This code is used to deploy karpenter pod to the EKS cluster and create config files for karpenter

# Adds the Karpenter add-on to the EKS cluster, adds AWS resources required by Karpenter, and configures Karpenter.
#
#Arguments:
# - `count`: Whether to create the Karpenter add-on. Defaults to 1.
# - `source`: The source of the module.
# - `cluster_name`: The name of the EKS cluster.
# - `irsa_oidc_provider_arn`: The OIDC provider ARN for the EKS cluster.
# - `policies`: A map of IAM policies to attach to the IAM role for Karpenter.
module "karpenter" {
  count                        = var.enable_karpenter ? 1 : 0
  source                       = "terraform-aws-modules/eks/aws//modules/karpenter"
  cluster_name                 = module.eks.cluster_name
  irsa_oidc_provider_arn       = module.eks.oidc_provider_arn
  policies = {
  AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

# Creates a Helm release for Karpenter, a Kubernetes cluster autoscaler. 
# This resource is conditional based on the value of the "enable_karpenter" variable.
# 
# Arguments:
# - `namespace`: The namespace in which to install Karpenter.
# - `create_namespace`: Whether to create the namespace if it doesn't exist.
# - `name`: The name of the Helm release.
# - `repository`: The OCI registry URL for the Karpenter container image.
# - `repository_username`: The username for the OCI registry.
# - `repository_password`: The password for the OCI registry.
# - `chart`: The name of the Helm chart to install.
# - `version`: The version of the Helm chart to install.
# - `set`: A list of key-value pairs to set as values for Karpenter's settings.
#     * `settings.aws.clusterName`: The name of the EKS cluster.
#     * `settings.aws.clusterEndpoint`: The endpoint for the EKS cluster.
#     * `serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn`: The ARN of the IAM role for Karpenter.
#     * `settings.aws.defaultInstanceProfile`: The name of the IAM instance profile for Karpenter.
#     * `settings.aws.interruptionQueueName`: The name of the SQS queue for Karpenter.
resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  namespace        = var.karpenter_namespace
  create_namespace = true
  
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "v0.28.0"

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter[0].irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter[0].instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter[0].queue_name
  }
}

# Gets an authorization token for the ECR Public registry.
#! Only works in us-east-1. 
data "aws_ecrpublic_authorization_token" "token" {
}

# Creates a Karpenter provisioner that will create instances based on the YAML configuration.
# Arguments:
# - `count`: Whether to create the Karpenter provisioner. Defaults to 1.
# - `yaml_body`: The YAML configuration for the Karpenter provisioner.
#     * `spec.requirements`: The rules for which instances to create.
#     * `spec.limits.resources.cpu`: The CPU limit for each instance.
#     * `spec.providerRef.name`: The name of the provider to use for the instances.
#     * `spec.ttlSecondsAfterEmpty`: The number of seconds to wait before deleting an instance after it becomes empty.
#     * `spec.ttlSecondsUntilExpired`: The number of seconds to wait before deleting an instance after it becomes idle.
resource "kubectl_manifest" "karpenter_provisioner" {
  count = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t2.small"]
      limits:
        resources:
          cpu: 1000
      providerRef:
        name: default
      ttlSecondsAfterEmpty: 30
      ttlSecondsUntilExpired: 2592000 
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}


# Creates a Karpenter node template this will be used to discover the subnets and security groups for the EKS cluster.
# Arguments:
# - `count`: Whether to create the Karpenter node template. Defaults to 1.
# - `yaml_body`: The YAML configuration for the Karpenter node template.
#     * `spec.subnetSelector.karpenter.sh/discovery`: The tag used for discovering the subnets for the EKS cluster.
#     * `spec.securityGroupSelector.karpenter.sh/discovery`: The tag used for discovering the security groups for the EKS cluster.
#     * `spec.tags.karpenter.sh/discovery`: The tag for discovering nodes for the EKS cluster.

resource "kubectl_manifest" "karpenter_node_template" {
  count = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
