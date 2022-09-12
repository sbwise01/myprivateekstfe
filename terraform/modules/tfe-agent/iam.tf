data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  name               = "${var.name_prefix}-tfe-agent-instance-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  tags = merge({ "Name" = "${var.name_prefix}-tfe-agent-instance-role" }, var.common_tags)
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name_prefix}-tfe-agent-instance-profile"
  path = "/"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy_attachment" "aws_ssm" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_service_linked_role" "tfe_agent_service_linked_role" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix    = "TFE-Agent"
}
