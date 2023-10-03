module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.16.0"
  cluster_name    = "eks-cluster"
  cluster_version = "1.27"
  

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
      # Define the node group for the worker nodes
      # Set the desired, minimum and maximum count of nodes
      min_size = var.node_group_minimum_instances
      desired_size = var.node_group_desired_instances
      max_size = var.node_group_maximum_instances

      # Set the instance types for the worker nodes
      instance_types = var.node_group_instance_types

      # Set the security groups for the worker nodes
      cluster_additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      capacity_type = "SPOT"

    }
    
  }

  enable_irsa = true

  
}

