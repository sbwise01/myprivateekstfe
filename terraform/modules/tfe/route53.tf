resource "aws_route53_record" "cert_validation_record" {
  count = var.load_balancer_type == "alb" && length(aws_acm_certificate.cert) == 1 ? 1 : 0

  name            = element(aws_acm_certificate.cert[0].domain_validation_options[*].resource_record_name, 0)
  type            = element(aws_acm_certificate.cert[0].domain_validation_options[*].resource_record_type, 0)
  records         = aws_acm_certificate.cert[0].domain_validation_options[*].resource_record_value
  zone_id         = var.route53_hosted_zone_acm
  ttl             = 60
  allow_overwrite = true
}

resource "aws_route53_record" "alias_record" {
  count = var.create_tfe_alias_record == true ? 1 : 0

  name    = var.tfe_hostname
  zone_id = var.route53_hosted_zone_tfe
  type    = "A"

  alias {
    name                   = var.load_balancer_type == "alb" ? aws_lb.alb[0].dns_name : aws_lb.nlb[0].dns_name
    zone_id                = var.load_balancer_type == "alb" ? aws_lb.alb[0].zone_id : aws_lb.nlb[0].zone_id
    evaluate_target_health = false
  }
}