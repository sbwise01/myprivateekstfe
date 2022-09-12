#-------------------------------------------------------------------------------------------------------------------------------------------
# S3 Bucket
#-------------------------------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "app" {
  bucket = "${var.friendly_name_prefix}-tfe-app-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-app-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}" },
    { "Description" = "TFE object storage" },
    var.common_tags
  )
}

resource "aws_s3_bucket_acl" "app" {
  bucket = aws_s3_bucket.app.id
  acl    = "private"
}

resource "aws_s3_bucket_logging" "app" {
  bucket = aws_s3_bucket.app.id

  target_bucket = var.s3_log_bucket_name
  target_prefix = "tfe/log/"
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfe.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_bucket_block_public" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# S3 Cross-Region Replication IAM
#-------------------------------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "s3_crr" {
  count = length(keys(var.bucket_replication_configuration)) > 0 && var.is_secondary == false ? 1 : 0

  name = "${var.friendly_name_prefix}-tfe-s3-crr-iam-role-${data.aws_region.current.name}"
  path = "/"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
POLICY

  tags = merge(
    { Name = "${var.friendly_name_prefix}-tfe-s3-crr-iam-role" },
    var.common_tags
  )
}

resource "aws_iam_policy" "s3_crr" {
  count = length(keys(var.bucket_replication_configuration)) > 0 && var.is_secondary == false ? 1 : 0

  name = "${var.friendly_name_prefix}-tfe-s3-crr-iam-policy-${data.aws_region.current.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.app.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.app.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.destination_bucket}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "s3_crr" {
  count = length(keys(var.bucket_replication_configuration)) > 0 && var.is_secondary == false ? 1 : 0

  name       = "${var.friendly_name_prefix}-tfe-s3-crr-iam-policy-attach-${data.aws_region.current.name}"
  roles      = [aws_iam_role.s3_crr[0].name]
  policy_arn = aws_iam_policy.s3_crr[0].arn
}