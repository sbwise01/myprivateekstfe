data "aws_route53_zone" "parent_zone" {
  name              = "aws.bradandmarsha.com."
}

resource "aws_route53_zone" "zone" {
  name              = "tfe.aws.bradandmarsha.com"
}

resource "aws_route53_record" "delegation" {
  allow_overwrite = true
  name            = "tfe"
  ttl             = 300
  type            = "NS"
  zone_id         = data.aws_route53_zone.parent_zone.id
  records         = aws_route53_zone.zone.name_servers
}
