resource "aws_security_group" "tfe_agent_ingress_allow" {
  name        = "${var.name_prefix}-tfe-agent-ec2-ingress-allow"
  description = "TFE agent EC2 instance ingress"
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" = "${var.name_prefix}-tfe-agent-ingress-allow" }, var.common_tags)
}

resource "aws_security_group" "tfe_agent_egress_allow" {
  name        = "${var.name_prefix}-tfe-agent-ec2-egress-allow"
  description = "TFE agent EC2 instance egress"
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" = "${var.name_prefix}-tfe-agent-egress-allow" }, var.common_tags)
}

resource "aws_security_group_rule" "tfe_agent_allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = var.egress_cidr_allow
  description = "Allow all traffic egress from TFE agent instance"

  security_group_id = aws_security_group.tfe_agent_egress_allow.id
}
