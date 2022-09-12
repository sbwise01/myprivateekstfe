data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "bootstrap_bucket" {
  count = var.tfe_bootstrap_bucket != "" ? 1 : 0

  bucket = var.tfe_bootstrap_bucket
}

data "aws_ecr_repository" "custom_tbw_image" {
  count = var.custom_tbw_ecr_repo != "" ? 1 : 0

  name = var.custom_tbw_ecr_repo
}

data "aws_s3_bucket" "log_bucket" {
  count = var.s3_log_bucket_name != "" ? 1 : 0

  bucket = var.s3_log_bucket_name
}

data "aws_cloudwatch_log_group" "log_group" {
  count = var.cloudwatch_log_group_name != "" ? 1 : 0

  name = var.cloudwatch_log_group_name
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}
