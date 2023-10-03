#https://blog.mikesir87.io/2021/12/deploying-karpenter-with-tf/
/*
resource "kubernetes_namespace" "karpenter" {
    metadata {
        name = "karpenter"
    }
  
}

module "iam_assumable_role_karpenter"{
    source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.30.0"
  create_role                   = true
  role_name                     = "karpenter-controller-eks-cluster"
  provider_url                  = module.eks.cluster_oidc_issuer_url
  oidc_fully_qualified_subjects = ["system:serviceaccount:${kubernetes_namespace.karpenter.metadata[0].name}:karpenter"]

}

resource "aws_iam_role_policy" "karpenter_contoller" {
  name = "karpenter-policy-eks-cluster"
  role = module.iam_assumable_role_karpenter.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role" "karpenter_node" {
  name = "karpenter-node-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

resource "helm_release" "karpenter" {
    depends_on = [ 
        module.iam_assumable_role_karpenter,
        aws_iam_role_policy.karpenter_contoller,
        aws_iam_role.karpenter_node
     ]

  namespace = kubernetes_namespace.karpenter.metadata[0].name
  create_namespace = false

  name = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart = "karpenter"
  version = "v0.31.0"

  

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_karpenter.iam_role_arn
  }

    set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name = "settings.aws.defaultInstanceProfile"
    value = "default"
  }
}

*/
/*
resource "kubectl_manifest" "karpenter_provisioner" {
  depends_on = [ helm_release.karpenter ]

 yaml_body = <<YAML
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  ttlSecondsAfterEmpty: 60 
  limits:
    resources:
      cpu: 100
  requirements:
    - key: karpenter.k8s.aws/instance-family
      operator: In
      values: [t2]
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot"]
    - key: karpenter.sh/instance-types
      operator: In
      values: ["micro, small"]
  providerRef:
    name: karpenter-provider
  consolidation:
    enabled: true
---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: karpenter-provider
spec:
  subnetSelector:
    kubernetes.io/cluster/${module.eks.cluster_name}: owned
  securityGroupSelector:
    kubernetes.io/cluster/${module.eks.cluster_name}: owned
YAML

}
*/