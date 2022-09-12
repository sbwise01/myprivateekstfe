resource "aws_db_subnet_group" "rds" {
  count = var.rds_is_aurora == false ? 1 : 0

  name       = "${var.friendly_name_prefix}-tfe-rds-subnet-group"
  subnet_ids = var.rds_subnet_ids

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-db-subnet-group" },
    { "Description" = "Subnets for TFE PostgreSQL RDS instance" },
    var.common_tags
  )
}

resource "aws_db_instance" "tfe" {
  count = var.rds_is_aurora == false ? 1 : 0

  engine                          = "postgres"
  engine_version                  = var.rds_engine_version
  identifier                      = "${var.friendly_name_prefix}-tfe-rds-${data.aws_caller_identity.current.account_id}"
  username                        = var.rds_username
  password                        = var.rds_password
  instance_class                  = var.rds_instance_class
  storage_type                    = "gp2"
  allocated_storage               = var.rds_allocated_storage
  multi_az                        = var.rds_multi_az
  db_subnet_group_name            = aws_db_subnet_group.rds[0].id
  publicly_accessible             = false
  vpc_security_group_ids          = [aws_security_group.rds_ingress_allow[0].id]
  port                            = 5432
  db_name                         = var.rds_database_name
  backup_retention_period         = var.rds_backup_retention_period
  backup_window                   = var.rds_preferred_backup_window
  final_snapshot_identifier       = "${var.friendly_name_prefix}-tfe-rds-${data.aws_caller_identity.current.account_id}-final-snapshot"
  skip_final_snapshot             = var.rds_skip_final_snapshot
  copy_tags_to_snapshot           = var.rds_copy_tags_to_snapshot
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.tfe.arn
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.tfe.arn
  allow_major_version_upgrade     = var.rds_allow_major_version_upgrade
  auto_minor_version_upgrade      = var.rds_auto_minor_version_upgrade
  maintenance_window              = var.rds_preferred_maintenance_window
  deletion_protection             = var.rds_deletion_protection

  tags = merge(
    { Name = "${var.friendly_name_prefix}-tfe-rds-${data.aws_caller_identity.current.account_id}" },
    { Description = "TFE PostgreSQL database storage" },
    var.common_tags
  )
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Security Groups
#-------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "rds_ingress_allow" {
  count = var.rds_is_aurora == false ? 1 : 0

  name        = "${var.friendly_name_prefix}-tfe-rds-ingress-allow"
  description = "TFE RDS ingress"
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" = "${var.friendly_name_prefix}-tfe-rds-allow" }, var.common_tags)
}

resource "aws_security_group_rule" "rds_ingress_allow_from_ec2" {
  count = var.rds_is_aurora == false ? 1 : 0

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_ingress_allow.id
  description              = "Allow PostgreSQL traffic inbound to TFE RDS from TFE EC2 Security Group"

  security_group_id = aws_security_group.rds_ingress_allow[0].id
}
