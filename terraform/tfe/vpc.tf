locals {
  eks_cluster_name = "${var.eks_cluster_name}-eks-${random_string.suffix.result}"
  tags         = {
    Name        = var.eks_cluster_name
    Terraform   = "true"
    Environment = "poc"
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}

module "vpc" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-vpc.git"

  name = var.eks_cluster_name
  cidr = var.vpc_cidr
  azs  = var.vpc_zones

  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  enable_nat_gateway = true

  tags = local.tags
}
