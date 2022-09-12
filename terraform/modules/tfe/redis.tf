resource "aws_elasticache_subnet_group" "tfe" {
  count = var.enable_active_active ? 1 : 0

  name       = "${var.friendly_name_prefix}-tfe-redis-subnet-group"
  subnet_ids = var.redis_subnet_ids
}

resource "aws_elasticache_replication_group" "redis_cluster" {
  count = var.enable_active_active ? 1 : 0

  engine                     = "redis"
  replication_group_id       = "${var.friendly_name_prefix}-tfe-redis-cluster"
  description                = "External Redis cluster for TFE Active/Active"
  engine_version             = var.redis_engine_version
  port                       = var.redis_port
  parameter_group_name       = var.redis_parameter_group_name
  node_type                  = var.redis_node_type
  num_cache_clusters         = length(var.redis_subnet_ids)
  multi_az_enabled           = var.redis_multi_az_enabled
  automatic_failover_enabled = var.redis_multi_az_enabled == true ? true : false
  subnet_group_name          = aws_elasticache_subnet_group.tfe[0].name
  security_group_ids         = [aws_security_group.redis_ingress_allow[0].id]
  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.tfe.arn
  transit_encryption_enabled = var.redis_password != "" ? true : false
  auth_token                 = var.redis_password != "" ? var.redis_password : null
  snapshot_retention_limit   = 0
  apply_immediately          = true
  auto_minor_version_upgrade = true

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-redis" }, var.common_tags)
}


#-------------------------------------------------------------------------------------------------------------------------------------------
# Security Groups
#-------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "redis_ingress_allow" {
  count = var.enable_active_active == true ? 1 : 0

  name   = "${var.friendly_name_prefix}-tfe-redis-ingress-allow"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-redis-ingress-allow" }, var.common_tags)
}

resource "aws_security_group_rule" "redis_ingress_allow_redis" {
  count = var.enable_active_active == true ? 1 : 0

  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_ingress_allow.id
  description              = "Allow Redis traffic ingress from TFE servers"

  security_group_id = aws_security_group.redis_ingress_allow[0].id
}
