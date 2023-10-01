<<<<<<< Updated upstream
=======
variable "cluster_name" {
  type = string
  description = "Name of the cluster"
  default = "eks-cluster"
}

variable "region" {
  type        = string
  description = "AWS region where the cluster will be located"
  default     = "us-east-1"
}

variable "vpc_name" {
  type = string
  description = "Name of the cluster VPC"
  default = "my-eks-vpc-1"
}

variable "vpc_availability_zones" {
    type = list(string)
    description = "AWS availability zones for the VPC"
    default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_private_subnets" {
    type = list(string)
    description = "Private IP subnets for the VPC"
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
    type = list(string)
    description = "Public IP subnets for the VPC"
    default = ["10.0.3.0/24", "10.0.4.0/24" ]
}

variable "node_group_instance_types" {
    type = list(string)
    description = "Instance types that will be used in the default node group"
    default = ["t2.small"]
}

variable "node_group_minimum_instances" {
  type = number
  description = "Minimum number of instances in the default node group"
  default = 1
}

variable "node_group_desired_instances" {
  type = number
  description = "Desired number of instances in the default node group"
  default = 1
}

variable "node_group_maximum_instances" {
  type = number
  description = "Maximum number of instances in the default node group"
  default = 3
}
>>>>>>> Stashed changes
