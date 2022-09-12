locals {
  user_data_args = {
    tfc_address     = var.tfc_address
    tfc_agent_token = var.tfc_agent_token
    tfc_agent_name  = var.tfc_agent_name
  }
}

resource "aws_launch_template" "lt" {
  name          = "${var.name_prefix}-tfe-agent-ec2-asg-lt"
  image_id      = data.aws_ami.amzn2.id
  instance_type = var.instance_size
  ebs_optimized = true
  user_data     = base64encode(templatefile("${path.module}/templates/tfe_agent_user_data.sh", local.user_data_args))


  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = var.ebs_volume_type
      volume_size = var.ebs_volume_size
      iops        = var.ebs_iops
      encrypted   = true
      kms_key_id  = var.kms_key_id == null ? aws_kms_key.tfe_agent.arn : var.kms_key_id
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  vpc_security_group_ids = [
    aws_security_group.tfe_agent_ingress_allow.id,
    aws_security_group.tfe_agent_egress_allow.id
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      "Name" = "${var.name_prefix}-tfe-agent-ec2"
      },
      var.common_tags
    )
  }
}

resource "aws_autoscaling_group" "asg" {
  name                    = "${var.name_prefix}-tfe-agent-asg"
  desired_capacity        = var.asg_instance_count
  max_size                = var.asg_max_size
  min_size                = 0
  vpc_zone_identifier     = var.ec2_subnet_ids
  service_linked_role_arn = aws_iam_service_linked_role.tfe_agent_service_linked_role.arn

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  depends_on = [
    aws_iam_service_linked_role.tfe_agent_service_linked_role
  ]
}
