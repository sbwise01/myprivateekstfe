terraform {
  required_version = "~> 1.1"
}

provider "aws" {
  region  = "us-east-1"
}

module "tfe-agent" {
  source = "../modules/tfe-agent"

  name_prefix = var.name_prefix
  common_tags = var.common_tags

  vpc_id            = var.vpc_id
  egress_cidr_allow = var.egress_cidr_allow
  ec2_subnet_ids    = data.aws_subnet_ids.private.ids

  tfc_address     = var.tfc_address
  tfc_agent_name  = var.tfc_agent_name
  tfc_agent_token = var.tfc_agent_token
}
