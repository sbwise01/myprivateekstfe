resource "aws_lb" "nlb" {
  count = var.load_balancer_type == "nlb" ? 1 : 0

  name               = "${var.friendly_name_prefix}-tfe-lb"
  load_balancer_type = "network"
  internal           = var.load_balancer_scheme == "external" ? false : true
  subnets            = var.lb_subnet_ids

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-lb" }, var.common_tags)
}

resource "aws_lb_listener" "lb_nlb_443" {
  count = var.load_balancer_type == "nlb" ? 1 : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_443[0].arn
  }
}

resource "aws_lb_listener" "lb_nlb_8800" {
  count = var.load_balancer_type == "nlb" && var.enable_active_active == false ? 1 : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = 8800
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_8800[0].arn
  }
}

resource "aws_lb_target_group" "nlb_443" {
  count = var.load_balancer_type == "nlb" ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe-nlb-tg-443"
  protocol = "TCP"
  port     = 443
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/_health_check"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-lb-tg-443" },
    { "Description" = "Load Balancer Target Group for TFE application traffic" },
    var.common_tags
  )
}

resource "aws_lb_target_group" "nlb_8800" {
  count = var.load_balancer_type == "nlb" && var.enable_active_active == false ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe-lb-tg-8800"
  port     = 8800
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-lb-tg-8800" },
    { "Description" = "Load Balancer Target Group for TFE/Replicated admin console traffic over port 8800" },
    var.common_tags
  )
}