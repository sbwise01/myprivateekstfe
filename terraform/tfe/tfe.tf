module "tfe" {
  source = "../modules/tfe"

  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  tfe_bootstrap_bucket    = var.tfe_bootstrap_bucket
  tfe_license_filepath    = var.tfe_license_filepath
  tfe_release_sequence    = var.tfe_release_sequence
  install_docker_before   = var.install_docker_before
  tfe_hostname            = var.tfe_hostname
  tfe_install_secrets_arn = var.tfe_install_secrets_arn
  console_password        = var.console_password
  enc_password            = var.enc_password

  log_forwarding_enabled    = var.log_forwarding_enabled
  log_forwarding_type       = var.log_forwarding_type
  cloudwatch_log_group_name = var.cloudwatch_log_group_name
  s3_log_bucket_name        = var.s3_log_bucket_name

  vpc_id                       = module.vpc.vpc_id
  lb_subnet_ids                = module.vpc.public_subnets
  ec2_subnet_ids               = module.vpc.private_subnets
  rds_subnet_ids               = module.vpc.private_subnets
  ingress_cidr_443_allow       = var.ingress_cidr_443_allow
  ingress_agent_pool_443_allow = var.ingress_agent_pool_443_allow
  ingress_cidr_8800_allow      = var.ingress_cidr_8800_allow
  ingress_cidr_22_allow        = var.ingress_cidr_22_allow
  egress_cidr_allow            = var.egress_cidr_allow
  load_balancer_scheme         = var.load_balancer_scheme
  route53_hosted_zone_acm      = aws_route53_zone.zone.id
  route53_hosted_zone_tfe      = aws_route53_zone.zone.id
  create_tfe_alias_record      = var.create_tfe_alias_record

  asg_health_check_grace_period = var.asg_health_check_grace_period
  asg_instance_count            = var.asg_instance_count
  asg_max_size                  = var.asg_max_size
  os_distro                     = var.os_distro
  ami_id                        = var.ami_id
  ssh_key_pair                  = var.ssh_key_pair
  aws_ssm_enable                = var.aws_ssm_enable

  rds_password            = var.rds_password
  rds_multi_az            = var.rds_multi_az
  rds_skip_final_snapshot = var.rds_skip_final_snapshot
  rds_engine_version      = var.rds_engine_version

  enable_active_active = var.enable_active_active
  redis_subnet_ids     = module.vpc.private_subnets
  redis_password       = var.redis_password
}
