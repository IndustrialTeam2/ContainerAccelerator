variable "cluster_name" {
  type = string
  description = "Name of the cluster"
  default = "eks-cluster"
  # category = "EKS"
  # input-type = "text"
}

variable "region" {
  type        = string
  description = "AWS region where the cluster will be located"
  default     = "us-east-1"
  # category    = "EKS"
  # input-type = "region"
}

variable "vpc_name" {
  type = string
  description = "Name of the cluster VPC"
  default = "my-eks-vpc-1"
  # category = "VPC"
  # input-type = "text"
}

variable "vpc_availability_zones" {
    type = list(string)
    description = "AWS availability zones for the VPC"
    default = ["us-east-1a", "us-east-1b"]
    # category = "VPC"
    # input-type = "zone"
}

variable "vpc_private_subnets" {
    type = list(string)
    description = "Private IP subnets for the VPC"
    default = ["10.0.1.0/24", "10.0.2.0/24"]
    # category = "VPC"
    # input-type = "text"
}

variable "vpc_public_subnets" {
    type = list(string)
    description = "Public IP subnets for the VPC"
    default = ["10.0.3.0/24", "10.0.4.0/24" ]
    # category = "VPC"
    # input-type = "text"
}

variable "vpc_cidr" {
    type = string
    description = "CIDR block for the VPC"
    default = "10.0.0.0/16"
}

variable "vpc_azs" {
  type = list(string)
  description = "Availability zones for the VPC"
  default = ["us-east-1a", "us-east-1b"]
}

variable "node_group_instance_types" {
    type = list(string)
    description = "Instance types that will be used in the default node group"
    default = ["t2.small"]
    # category = "EKS"
    # input-type = "instance-type"
}

variable "node_group_minimum_instances" {
  type = number
  description = "Minimum number of instances in the default node group"
  default = 1
  # category = "EKS"
  # input-type = "number"
}

variable "node_group_desired_instances" {
  type = number
  description = "Desired number of instances in the default node group"
  default = 1
  # category = "EKS"
  # input-type = "number"
}

variable "node_group_maximum_instances" {
  type = number
  description = "Maximum number of instances in the default node group"
  default = 3
  # category = "EKS"
  # input-type = "number"
}

variable "node_group_capacity_type" {
  type = string
  description = "Instance types that will be used in the default node group"
  default = "SPOT"
}

variable "enable_monitoring" {
  type = bool
  description = "Enable/disable cluster monitoring"
  default = true
}


variable "enable_node_monitoring" {
  type = bool
  description = "Enable/disable node monitoring (monitoring needs to be enabled for this to work)"
  default = true
}

variable "enable_kube_state_metrics" {
  type = bool
  description = "Enable/diable kube state metrics monitoring data collection (monitoring needs to be enabled for this to work)"
  default = true
}

variable "enable_cadvisor_metrics"{
  type = bool
  description = "Enable/disable cadvisor metrics collection (monitoring needs to be enabled for this to work)"
  default = true
}

variable "monitoring_namespace" {
  type = string
  description = "Namespace where monitoring tools will be deployed"
  default = "monitoring"
}

variable "enable_karpenter" {
  type = bool
  description = "Enable/disable karpenter"
  default = true
}

variable "karpenter_namespace" {
  type = string
  description = "Namespace where karpenter will be deployed"
  default = "karpenter"
}

variable "vpc_tags" {
  type = map(string)
  description = "Tags for the VPC"
  default = {
    Name = "my-eks-vpc-1"
  }
}

variable "node_group_tags" {
  type = map(string)
  description = "Tags for the default node group"
  default = {
    Name = "my-eks-node-group-1"
  }
}
  
variable "eks_tags" {
  type = map(string)
  description = "Tags for the EKS cluster"
  default = {
    Name = "my-eks-cluster-1"
  }
}
  
