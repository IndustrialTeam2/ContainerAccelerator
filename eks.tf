module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.16.0"
  cluster_version = "1.27"
  cluster_name    = var.cluster_name
  

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true


  eks_managed_node_group_defaults = {

    instance_types = ["t2.micro"]

    managed_test = {
      min_size     = 1
      desired_size = 1
      max_size     = 3
cluster_additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      # SPOT: spare capacity of unused EC2 instances at steep discounts
      # ON_DEMAND: pay for compute capacity by the second with no long-term commitments
      capacity_type = "SPOT"

    }
  }

  eks_managed_node_groups = {
    default_node_group = {
      min_size = var.node_group_minimum_instances
      desired_size = var.node_group_desired_instances
      max_size = var.node_group_maximum_instances

      instance_types = var.node_group_instance_types
      cluster_additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      capacity_type = "SPOT"
    }
  }

  enable_irsa = true
}
