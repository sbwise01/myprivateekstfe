resource "aws_iam_role" "instance_role" {
  name               = "${var.friendly_name_prefix}-tfe-instance-role-${data.aws_region.current.name}"
  path               = "/"
  assume_role_policy = file("${path.module}/templates/tfe-instance-role.json")

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-instance-role" }, var.common_tags)
}

resource "aws_iam_role_policy" "instance_role_policy" {
  name = "${var.friendly_name_prefix}-tfe-instance-role-policy-${data.aws_region.current.name}"
  policy = templatefile(
    "${path.module}/templates/tfe-instance-role-policy.json",
    {
      app_bucket_arn           = aws_s3_bucket.app.arn,
      bootstrap_bucket_arn     = var.tfe_bootstrap_bucket != "" ? data.aws_s3_bucket.bootstrap_bucket[0].arn : "",
      kms_key_arn              = aws_kms_key.tfe.arn,
      tfe_install_secrets_arn  = var.tfe_install_secrets_arn,
      tfe_cert_secret_arn      = var.tfe_cert_secret_arn,
      tfe_privkey_secret_arn   = var.tfe_privkey_secret_arn,
      ca_bundle_secret_arn     = var.ca_bundle_secret_arn,
      custom_tbw_ecr_repo_arn  = var.custom_tbw_ecr_repo != "" ? data.aws_ecr_repository.custom_tbw_image[0].arn : "",
      log_forwarding_enabled   = var.log_forwarding_enabled
      s3_log_bucket_arn        = var.s3_log_bucket_name != "" ? data.aws_s3_bucket.log_bucket[0].arn : ""
      cloudwatch_log_group_arn = var.cloudwatch_log_group_name != "" ? data.aws_cloudwatch_log_group.log_group[0].arn : ""
    }
  )
  role = aws_iam_role.instance_role.id
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.friendly_name_prefix}-tfe-instance-profile-${data.aws_region.current.name}"
  path = "/"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy_attachment" "aws_ssm" {
  count = var.aws_ssm_enable == true ? 1 : 0

  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_service_linked_role" "tfe_service_linked_role" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix    = "TFE"
}
