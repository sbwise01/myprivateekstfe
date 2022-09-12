#-------------------------------------------------------------------------------------------------------------------------------------------
# Application Load Balancer
#-------------------------------------------------------------------------------------------------------------------------------------------
resource "aws_lb" "alb" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  name = "${var.friendly_name_prefix}-tfe-web-alb"
  # Added tfsec ignore comment here because the implementation intentionally creates an external load balancer for use with github hooks
  internal                   = var.load_balancer_scheme == "external" ? false : true #tfsec:ignore:aws-elb-alb-not-public
  load_balancer_type         = "application"
  subnets                    = var.lb_subnet_ids
  drop_invalid_header_fields = true

  security_groups = [
    aws_security_group.alb_ingress_allow[0].id,
    aws_security_group.alb_egress_allow[0].id
  ]

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-alb" }, var.common_tags)
}

resource "aws_lb_listener" "alb_443" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = element(coalescelist(aws_acm_certificate.cert[*].arn, tolist([var.tfe_tls_certificate_arn])), 0)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_443[0].arn
  }

  depends_on = [aws_acm_certificate.cert]
}

resource "aws_lb_listener" "alb_8800" {
  count = var.load_balancer_type == "alb" && var.enable_active_active == false ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn
  port              = 8800
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = element(coalescelist(aws_acm_certificate.cert[*].arn, tolist([var.tfe_tls_certificate_arn])), 0)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_8800[0].arn
  }

  depends_on = [aws_acm_certificate.cert[0]]
}

resource "aws_lb_target_group" "alb_443" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe-alb-tg-443"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/_health_check"
    healthy_threshold   = 2
    unhealthy_threshold = 7
    timeout             = 5
    interval            = 30
    matcher             = 200
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-alb-tg-443" },
    { "Description" = "ALB Target Group for TFE web application HTTPS traffic" },
    var.common_tags
  )
}

resource "aws_lb_target_group" "alb_8800" {
  count = var.load_balancer_type == "alb" && var.enable_active_active == false ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe-alb-tg-8800"
  port     = 8800
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 7
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-alb-tg-8800" },
    { "Description" = "ALB Target Group for TFE/Replicated web admin console traffic over port 8800" },
    var.common_tags
  )
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Security Groups
#-------------------------------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "alb_ingress_allow" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  name        = "${var.friendly_name_prefix}-tfe-lb-allow"
  description = "TFE ALB ingress"
  vpc_id      = var.vpc_id

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-lb-allow" }, var.common_tags)
}

resource "aws_security_group_rule" "alb_ingress_allow_https" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  # Added tfsec ignore comment here because the implementation is passing in a restrictive CIDR list
  cidr_blocks = var.ingress_cidr_443_allow #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  description = "Allow HTTPS (port 443) traffic inbound to TFE LB"

  security_group_id = aws_security_group.alb_ingress_allow[0].id
}

resource "aws_security_group_rule" "alb_ingress_allow_console" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  type        = "ingress"
  from_port   = 8800
  to_port     = 8800
  protocol    = "tcp"
  cidr_blocks = concat([data.aws_vpc.selected.cidr_block], var.ingress_cidr_8800_allow)
  description = "Allow admin console (port 8800) traffic inbound to TFE LB for TFE Replicated admin console"

  security_group_id = aws_security_group.alb_ingress_allow[0].id
}

resource "aws_security_group" "alb_egress_allow" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  name   = "${var.friendly_name_prefix}-tfe-alb-egress-allow"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-alb-egress-allow" }, var.common_tags)
}

resource "aws_security_group_rule" "alb_egress_instances_443" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_ingress_allow.id
  description              = "Allow (port 443) traffic outbount to TFE instances"

  security_group_id = aws_security_group.alb_egress_allow[0].id
}

resource "aws_security_group_rule" "alb_ingress_allow_agent_pool" {
  count = var.load_balancer_type == "alb" && var.ingress_agent_pool_443_allow != null ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.ingress_agent_pool_443_allow
  description              = "Allow agent pool HTTPS (port 443) traffic inbound to TFE LB"

  security_group_id = aws_security_group.alb_ingress_allow[0].id
}

resource "aws_security_group_rule" "alb_egress_instances_8800" {
  count = var.load_balancer_type == "alb" ? 1 : 0

  type                     = "egress"
  from_port                = 8800
  to_port                  = 8800
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_ingress_allow.id
  description              = "Allow (port 8800) management traffic outbount to TFE instances"

  security_group_id = aws_security_group.alb_egress_allow[0].id
}
