#-------------------------------------------------------------------------------------------------------------------------------------------
# AMI
#-------------------------------------------------------------------------------------------------------------------------------------------
data "aws_ami" "amzn2" {
  count = var.os_distro == "amzn2" && var.ami_id == null ? 1 : 0

  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "ubuntu" {
  count = var.os_distro == "ubuntu" && var.ami_id == null ? 1 : 0

  owners      = ["099720109477", "513442679011"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "rhel" {
  count = var.os_distro == "rhel" && var.ami_id == null ? 1 : 0

  owners      = ["309956199498"]
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-7.*_HVM-*-x86_64-0-Hourly2-GP2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "centos" {
  count = var.os_distro == "centos" && var.ami_id == null ? 1 : 0

  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Launch Template
#-------------------------------------------------------------------------------------------------------------------------------------------

locals {
  image_id_list = tolist([var.ami_id, join("", data.aws_ami.amzn2.*.image_id), join("", data.aws_ami.ubuntu.*.image_id), join("", data.aws_ami.rhel.*.image_id), join("", data.aws_ami.centos.*.image_id)])

  root_device_name = lookup({ "amzn2" = "/dev/xvda", "ubuntu" = "/dev/sda1", "rhel" = "/dev/sda1", "centos" = "/dev/sda1" }, var.os_distro, "/dev/sda1")

  custom_image_tag = var.custom_tbw_ecr_repo != "" ? "${data.aws_ecr_repository.custom_tbw_image[0].repository_url}:${var.custom_tbw_image_tag}" : "hashicorp/build-worker:now"
}

locals {
  fluent_bit_cloudwatch_args = {
    region               = data.aws_region.current.name
    cloudwatch_log_group = var.cloudwatch_log_group_name
  }
  fluent_bit_cloudwatch_config = var.log_forwarding_type == "cloudwatch" ? (templatefile("${path.module}/templates/fluent-bit-cloudwatch.conf.tpl", local.fluent_bit_cloudwatch_args)) : ""

  fluent_bit_s3_args = {
    region        = data.aws_region.current.name
    s3_log_bucket = var.s3_log_bucket_name
  }
  fluent_bit_s3_config = var.log_forwarding_type == "s3" ? (templatefile("${path.module}/templates/fluent-bit-s3.conf.tpl", local.fluent_bit_s3_args)) : ""

  fluent_bit_custom_config = var.log_forwarding_type == "custom" ? var.custom_fluent_bit_config : ""

  fluent_bit_config = join("", [local.fluent_bit_cloudwatch_config, local.fluent_bit_s3_config, local.fluent_bit_custom_config])
}

locals {
  user_data_args = {
    airgap_install                  = var.airgap_install
    pkg_repos_reachable_with_airgap = var.pkg_repos_reachable_with_airgap
    install_docker_before           = var.install_docker_before
    replicated_bundle_path          = var.replicated_bundle_path
    tfe_airgap_bundle_path          = var.tfe_airgap_bundle_path
    tfe_license_filepath            = var.tfe_license_filepath
    tfe_release_sequence            = var.tfe_release_sequence
    tls_bootstrap_type              = var.tls_bootstrap_type
    tfe_cert_secret_arn             = var.tfe_cert_secret_arn
    tfe_privkey_secret_arn          = var.tfe_privkey_secret_arn
    ca_bundle_secret_arn            = var.ca_bundle_secret_arn
    tfe_install_secrets_arn         = var.tfe_install_secrets_arn
    console_password                = var.console_password
    enc_password                    = var.enc_password
    remove_import_settings_from     = var.remove_import_settings_from
    http_proxy                      = var.http_proxy
    extra_no_proxy                  = var.extra_no_proxy
    hairpin_addressing              = var.hairpin_addressing == true ? 1 : 0
    tfe_hostname                    = var.tfe_hostname
    tbw_image                       = var.tbw_image
    custom_tbw_ecr_repo_uri         = var.custom_tbw_ecr_repo != "" ? data.aws_ecr_repository.custom_tbw_image[0].repository_url : ""
    custom_image_tag                = local.custom_image_tag
    capacity_concurrency            = var.capacity_concurrency
    capacity_memory                 = var.capacity_memory
    enable_metrics_collection       = var.enable_metrics_collection == true ? 1 : 0
    metrics_endpoint_enabled        = var.metrics_endpoint_enabled == true ? 1 : 0
    metrics_endpoint_port_http      = var.metrics_endpoint_port_http
    metrics_endpoint_port_https     = var.metrics_endpoint_port_https
    force_tls                       = var.force_tls == true ? 1 : 0
    restrict_worker_metadata_access = var.restrict_worker_metadata_access == true ? 1 : 0
    kms_key_arn                     = aws_kms_key.tfe.arn
    s3_app_bucket_name              = aws_s3_bucket.app.id
    s3_app_bucket_region            = data.aws_region.current.name
    pg_netloc                       = var.rds_is_aurora == true ? aws_rds_cluster.tfe[0].endpoint : aws_db_instance.tfe[0].endpoint
    pg_dbname                       = var.rds_is_aurora == true ? aws_rds_cluster.tfe[0].database_name : aws_db_instance.tfe[0].name
    pg_user                         = var.rds_is_aurora == true ? aws_rds_cluster.tfe[0].master_username : aws_db_instance.tfe[0].username
    pg_password                     = var.rds_password
    enable_active_active            = var.enable_active_active == true ? 1 : 0
    redis_host                      = var.enable_active_active == true ? aws_elasticache_replication_group.redis_cluster[0].primary_endpoint_address : ""
    redis_pass                      = var.enable_active_active == true ? var.redis_password : ""
    redis_port                      = var.enable_active_active == true ? var.redis_port : ""
    redis_use_password_auth         = var.enable_active_active == true && var.redis_password != "" ? 1 : 0
    redis_use_tls                   = var.enable_active_active == true && var.redis_password != "" ? 1 : 0
    log_forwarding_enabled          = var.log_forwarding_enabled == true ? 1 : 0
    log_forwarding_type             = var.log_forwarding_type
    fluent_bit_config               = local.fluent_bit_config
  }
}

resource "aws_launch_template" "lt" {
  name          = "${var.friendly_name_prefix}-tfe-ec2-asg-lt"
  image_id      = coalesce(local.image_id_list...)
  instance_type = var.instance_size
  key_name      = var.ssh_key_pair
  user_data     = base64encode(templatefile("${path.module}/templates/tfe_user_data.sh.tpl", local.user_data_args))

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  vpc_security_group_ids = [
    aws_security_group.ec2_ingress_allow.id,
    aws_security_group.ec2_egress_allow.id
  ]

  block_device_mappings {
    device_name = local.root_device_name

    ebs {
      volume_type = var.ebs_volume_type
      volume_size = var.ebs_volume_size
      throughput  = var.ebs_throughput
      iops        = var.ebs_iops
      encrypted   = true
      kms_key_id  = aws_kms_key.tfe.arn
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.friendly_name_prefix}-tfe-ec2" },
      { "Type" = "autoscaling-group" },
      { "OS_Distro" = var.os_distro },
      var.common_tags
    )
  }

  tags = merge({
    "Name"          = "${var.friendly_name_prefix}-tfe-ec2-launch-template"
    "Active-Active" = var.enable_active_active
    },
    var.common_tags
  )
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Autoscaling Group
#-------------------------------------------------------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "asg" {
  name                      = "${var.friendly_name_prefix}-tfe-asg"
  min_size                  = 0
  max_size                  = var.enable_active_active == false ? 1 : var.asg_max_size
  desired_capacity          = var.asg_instance_count
  vpc_zone_identifier       = var.ec2_subnet_ids
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = "ELB"
  service_linked_role_arn   = aws_iam_service_linked_role.tfe_service_linked_role.arn

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = var.enable_active_active == true ? [var.load_balancer_type == "alb" ? aws_lb_target_group.alb_443[0].arn : aws_lb_target_group.nlb_443[0].arn] : [
    var.load_balancer_type == "alb" ? aws_lb_target_group.alb_443[0].arn : aws_lb_target_group.nlb_443[0].arn,
    var.load_balancer_type == "alb" ? aws_lb_target_group.alb_8800[0].arn : aws_lb_target_group.nlb_8800[0].arn
  ]

  tag {
    key                 = "Name"
    value               = "${var.friendly_name_prefix}-tfe-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Active-Active"
    value               = var.enable_active_active
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  depends_on = [aws_rds_cluster_instance.tfe[0]]
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Security Groups
#-------------------------------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "ec2_ingress_allow" {
  name        = "${var.friendly_name_prefix}-tfe-ec2-ingress-allow"
  description = "TFE EC2 instance ingress"
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" = "${var.friendly_name_prefix}-tfe-ec2-ingress-allow" }, var.common_tags)
}

resource "aws_security_group_rule" "ec2_ingress_allow_https_from_lb" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_egress_allow[0].id
  description              = "Allow HTTPS (port 443) traffic inbound to TFE EC2 instance from TFE LB"

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_https" {
  count = var.load_balancer_type == "nlb" ? 1 : 0

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.ingress_cidr_443_allow
  description = "Allow HTTPS (port 443) traffic inbound to TFE EC2 instance"

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_console_from_lb" {
  count = var.load_balancer_type == "alb" && var.enable_active_active != true ? 1 : 0

  type                     = "ingress"
  from_port                = 8800
  to_port                  = 8800
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_egress_allow[0].id
  description              = "Allow admin console (port 8800) traffic inbound to TFE EC2 instance from TFE LB"

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_console" {
  count = var.load_balancer_type == "nlb" && var.enable_active_active != true ? 1 : 0

  type        = "ingress"
  from_port   = 8800
  to_port     = 8800
  protocol    = "tcp"
  cidr_blocks = data.aws_vpc.selected.cidr_block
  description = "Allow admin console (port 8800) traffic inbound to TFE LB for TFE Replicated admin console"

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_ssh" {
  count       = length(var.ingress_cidr_22_allow) > 0 ? 1 : 0
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.ingress_cidr_22_allow
  description = "Allow SSH inbound to TFE EC2 instance CIDR ranges listed"

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_vault" {
  count = var.enable_active_active == true ? 1 : 0

  type        = "ingress"
  from_port   = 8201
  to_port     = 8201
  protocol    = "tcp"
  self        = true
  description = "Allow embedded Vault instances to communicate with each other in HA mode"

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group" "ec2_egress_allow" {
  name        = "${var.friendly_name_prefix}-tfe-ec2-egress-allow"
  description = "TFE EC2 instance egress"
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" = "${var.friendly_name_prefix}-tfe-egress-allow" }, var.common_tags)
}

resource "aws_security_group_rule" "ec2_allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = var.egress_cidr_allow
  description = "Allow all traffic egress from TFE"

  security_group_id = aws_security_group.ec2_egress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_metrics_http_cidr" {
  count = var.metrics_endpoint_enabled == true && var.metrics_endpoint_allow_cidr != null ? 1 : 0

  type        = "ingress"
  from_port   = var.metrics_endpoint_port_http
  to_port     = var.metrics_endpoint_port_http
  protocol    = "tcp"
  cidr_blocks = var.metrics_endpoint_allow_cidr
  description = "Allow external monitoring tools to gather TFE metrics."

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_metrics_https_cidr" {
  count = var.metrics_endpoint_enabled == true && var.metrics_endpoint_allow_cidr != null ? 1 : 0

  type        = "ingress"
  from_port   = var.metrics_endpoint_port_https
  to_port     = var.metrics_endpoint_port_https
  protocol    = "tcp"
  cidr_blocks = var.metrics_endpoint_allow_cidr
  description = "Allow external monitoring tools to gather TFE metrics."

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_metrics_http_sg" {
  count = var.metrics_endpoint_enabled == true && var.metrics_endpoint_allow_sg != null ? 1 : 0

  type                     = "ingress"
  from_port                = var.metrics_endpoint_port_http
  to_port                  = var.metrics_endpoint_port_http
  protocol                 = "tcp"
  source_security_group_id = var.metrics_endpoint_allow_sg
  description              = "Allow external monitoring tools to gather TFE metrics."

  security_group_id = aws_security_group.ec2_ingress_allow.id
}

resource "aws_security_group_rule" "ec2_ingress_allow_metrics_https_sg" {
  count = var.metrics_endpoint_enabled == true && var.metrics_endpoint_allow_sg != null ? 1 : 0

  type                     = "ingress"
  from_port                = var.metrics_endpoint_port_https
  to_port                  = var.metrics_endpoint_port_https
  protocol                 = "tcp"
  source_security_group_id = var.metrics_endpoint_allow_sg
  description              = "Allow external monitoring tools to gather TFE metrics."

  security_group_id = aws_security_group.ec2_ingress_allow.id
}
