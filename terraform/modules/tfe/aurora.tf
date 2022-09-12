resource "aws_db_subnet_group" "aurora" {
  count = var.rds_is_aurora == true ? 1 : 0

  name       = "${var.friendly_name_prefix}-tfe-aurora-subnet-group"
  subnet_ids = var.rds_subnet_ids

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-db-subnet-group" },
    { "Description" = "Subnets for TFE PostgreSQL RDS instance" },
    var.common_tags
  )
}

resource "aws_rds_global_cluster" "tfe" {
  count = var.rds_is_aurora == true && var.is_secondary == false ? 1 : 0

  global_cluster_identifier = "${var.friendly_name_prefix}-tfe-rds-global-cluster"
  database_name             = var.rds_database_name
  deletion_protection       = false
  engine                    = "aurora-postgresql"
  engine_version            = var.aurora_rds_engine_version
  storage_encrypted         = true
}

resource "aws_rds_cluster" "tfe" {
  count = var.rds_is_aurora == true ? 1 : 0

  global_cluster_identifier       = var.is_secondary == true ? var.aurora_rds_global_cluster_id : aws_rds_global_cluster.tfe[0].id
  cluster_identifier              = "${var.friendly_name_prefix}-tfe-rds-cluster-${data.aws_region.current.name}"
  engine                          = "aurora-postgresql"
  engine_mode                     = var.aurora_rds_engine_mode
  engine_version                  = var.aurora_rds_engine_version
  database_name                   = var.is_secondary == true ? null : var.rds_database_name
  availability_zones              = var.aurora_rds_availability_zones
  db_subnet_group_name            = aws_db_subnet_group.aurora[0].id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.tfe[0].id
  port                            = 5432
  master_username                 = var.is_secondary == true ? null : var.rds_username
  master_password                 = var.is_secondary == true ? null : var.rds_password
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.tfe.arn
  vpc_security_group_ids          = [aws_security_group.aurora_ingress_allow[0].id]
  replication_source_identifier   = var.is_secondary == true ? var.aurora_rds_replication_source_identifier : null
  source_region                   = var.is_secondary == false ? null : var.aurora_source_region
  backup_retention_period         = var.rds_backup_retention_period
  preferred_backup_window         = var.rds_preferred_backup_window
  preferred_maintenance_window    = var.rds_preferred_maintenance_window
  skip_final_snapshot             = var.rds_skip_final_snapshot
  final_snapshot_identifier       = "${var.friendly_name_prefix}-tfe-rds-final-snapshot-${data.aws_region.current.name}"

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-rds-cluster-${data.aws_region.current.name}" },
    { "Description" = "TFE RDS Aurora PostgreSQL database cluster" },
    { "Is_Secondary" = var.is_secondary },
    var.common_tags
  )

  lifecycle {
    ignore_changes = [replication_source_identifier]
  }
}

resource "aws_rds_cluster_instance" "tfe" {
  count = var.rds_is_aurora ? var.aurora_rds_replica_count + 1 : 0

  identifier              = "${var.friendly_name_prefix}-tfe-rds-cluster-instance-${count.index}"
  cluster_identifier      = aws_rds_cluster.tfe[0].id
  instance_class          = var.aurora_rds_instance_class
  engine                  = aws_rds_cluster.tfe[0].engine
  engine_version          = aws_rds_cluster.tfe[0].engine_version
  db_parameter_group_name = aws_db_parameter_group.tfe[0].id
  apply_immediately       = true
  publicly_accessible     = false

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-rds-cluster-instance-${count.index}" },
    { "Description" = "TFE RDS Aurora PostgreSQL DB cluster instance" },
    { "Is_Secondary" = var.is_secondary },
    var.common_tags
  )
}

resource "aws_rds_cluster_parameter_group" "tfe" {
  count = var.rds_is_aurora == true ? 1 : 0

  name        = "${var.friendly_name_prefix}-tfe-rds-cluster-parameter-group-${data.aws_region.current.name}"
  family      = "aurora-postgresql12"
  description = "TFE RDS Aurora PostgreSQL DB cluster parameter group"
}

resource "aws_db_parameter_group" "tfe" {
  count = var.rds_is_aurora == true ? 1 : 0

  name        = "${var.friendly_name_prefix}-tfe-rds-db-parameter-group-${data.aws_region.current.name}"
  family      = "aurora-postgresql12"
  description = "TFE RDS Aurora PostgreSQL DB instance parameter group"
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Security Groups
#-------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "aurora_ingress_allow" {
  count = var.rds_is_aurora == true ? 1 : 0

  name   = "${var.friendly_name_prefix}-tfe-aurora-ingress-allow"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-aurora-ingress-allow" }, var.common_tags)
}

resource "aws_security_group_rule" "allow_aurora_from_ec2" {
  count = var.rds_is_aurora == true ? 1 : 0

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_ingress_allow.id
  description              = "Allow PostgreSQL traffic inbound to TFE Aurora from TFE EC2 Security Group"

  security_group_id = aws_security_group.aurora_ingress_allow[0].id
}

