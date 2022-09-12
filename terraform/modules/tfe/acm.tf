resource "aws_acm_certificate" "cert" {
  count = var.load_balancer_type == "alb" && var.tfe_tls_certificate_arn == null ? 1 : 0

  domain_name       = var.tfe_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-lb-acm-cert" }, var.common_tags)
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count = length(aws_acm_certificate.cert) == 1 ? 1 : 0

  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation_record[0].fqdn]
}