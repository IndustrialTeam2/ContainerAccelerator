# This creates a vpc in which the resources will be deployed
#
# Arguments:
# - `name`: The name of the VPC.
# - `azs`: A list of availability zones in the region.
# - `cidr`: The CIDR block of the VPC.
# - `instance_tenancy`: A tenancy option for instances launched into the VPC.
# - `private_subnets`: A list of private subnets inside the VPC.
# - `public_subnets`: A list of public subnets inside the VPC.
# - `enable_nat_gateway`: Whether to create a NAT gateway for each private subnet. 
# - `single_nat_gateway`: Whether to create a single shared NAT gateway across all of the private subnets. 
# - `enable_dns_hostnames`: Whether to enable DNS hostnames in the VPC. 
# - `enable_dns_support`: Whether to enable DNS support in the VPC.
# - `tags`: A mapping of tags to assign to the resource.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  azs  = var.vpc_azs
  cidr = var.vpc_cidr

  instance_tenancy = "default"

  private_subnets      = var.vpc_private_subnets
  public_subnets       = var.vpc_public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support = true


 
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "karpenter.sh/discovery" = var.cluster_name
  }
}

