provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "parent_zone" {
  name              = "aws.bradandmarsha.com"
  delegation_set_id = "N03386422VXZJKGR4YO18"
}
