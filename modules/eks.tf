# Module for creating the EKS cluster
#
# Arguments:
# - `cluster_name`: The name of the EKS cluster.
# - `cluster_version`: The Kubernetes version for the EKS cluster.
# - `vpc_id`: The ID of the VPC in which to create the EKS cluster.
# - `subnet_ids`: A list of subnet IDs in which the EKS cluster nodes will be deployed.
# - `cluster_endpoint_private_access`: Whether to enable private access to the EKS cluster endpoint.
# - `cluster_endpoint_public_access`: Whether to enable public access to the EKS cluster endpoint.
# - `create_node_security_group`: Whether to create a security group for the EKS cluster nodes.
# - `eks_managed_node_groups`: A map of EKS managed node groups to create.
#     * `attach_cluster_primary_security_group`: Whether to attach the EKS cluster's primary security group to the node group.
#     * `min_size`: The minimum number of nodes in the node group.
#     * `desired_size`: The initial number of nodes in the node group.
#     * `max_size`: The maximum number of nodes in the node group.
#     * `instance_types`: A list of instance types to use for the node group.
#     * `capacity_type`: The capacity type for the node group.
# - `enable_irsa`: Whether to enable IAM Roles for Service Accounts (IRSA).
# - `manage_aws_auth_configmap`: Whether to manage the aws-auth ConfigMap.
# - `aws_auth_roles`: A list of IAM roles to add to the aws-auth ConfigMap.
#     * `rolearn`: The ARN of the IAM role.
#     * `username`: The username to associate with the IAM role.
#     * `groups`: A list of groups to associate with the IAM role.
# - `tags`: A map of tags to associate with the EKS cluster.
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.16.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  create_node_security_group            = false 
  eks_managed_node_groups = {
    default_node_group = {
  attach_cluster_primary_security_group = true 
      min_size = var.node_group_minimum_instances
      desired_size = var.node_group_desired_instances
      max_size = var.node_group_maximum_instances
      instance_types = var.node_group_instance_types

      capacity_type = var.node_group_capacity_type

    }
    
  }
  enable_irsa = true
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.karpenter[0].role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },{
      rolearn = aws_iam_role.eks_cluster_developer.arn
      username = "developer"
      groups = [
        "system:masters",
      ]
    }
  ]
  
  tags = {
    "karpenter.sh/discovery" = "eks-cluster"
  }
}

