data "aws_iam_policy_document" "tfe_role_policy" {
  statement {
    sid    = "Admin"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow TFE instance profile role use of the customer managed key"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_service_linked_role.tfe_service_linked_role.arn,
        aws_iam_role.instance_role.arn
      ]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_service_linked_role.tfe_service_linked_role.arn,
        aws_iam_role.instance_role.arn
      ]
    }
    actions = [
      "kms:CreateGrant"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "tfe" {
  description             = "KMS key used to encrypt TFE RDS, S3, EBS, and Redis resources"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.tfe_role_policy.json
}
