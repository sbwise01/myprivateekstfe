data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.selected.id
  filter {
    name   = "tag:${var.private_subnets_tag_key}"
    values = [var.private_subnets_tag_value]
  }
}
