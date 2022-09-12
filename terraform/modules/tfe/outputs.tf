#------------------------------------------------------------------------------------------------------------------
# TFE URLs
#------------------------------------------------------------------------------------------------------------------
output "url" {
  value       = "https://${var.tfe_hostname}"
  description = "URL of TFE application based on `tfe_hostname` input."
}

output "admin_console_url" {
  value       = "https://${var.tfe_hostname}:8800"
  description = "URL of TFE (Replicated) Admin Console based on `tfe_hostname` input."
}

output "lb_dns_name" {
  value       = var.load_balancer_type == "alb" ? aws_lb.alb[0].dns_name : aws_lb.nlb[0].dns_name
  description = "DNS name of the Load Balancer."
}


#------------------------------------------------------------------------------------------------------------------
# External Services
#------------------------------------------------------------------------------------------------------------------
output "s3_bucket_name" {
  value       = aws_s3_bucket.app.id
  description = "Name of TFE S3 bucket."
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.app.arn
  description = "ARN of TFE S3 bucket."
}

output "s3_crr_iam_role_arn" {
  value       = aws_iam_role.s3_crr.*.arn
  description = "ARN of S3 Cross-Region Replication IAM Role."
}

output "aurora_rds_global_cluster_id" {
  value       = aws_rds_global_cluster.tfe.*.id
  description = "Aurora Global Database cluster identifier."
}

output "aurora_rds_cluster_arn" {
  value       = aws_rds_cluster.tfe.*.arn
  description = "ARN of Aurora DB cluster."
  depends_on  = [aws_rds_cluster_instance.tfe]
}

output "aurora_rds_cluster_members" {
  value       = aws_rds_cluster.tfe.*.cluster_members
  description = "List of instances that are part of this Aurora DB Cluster."
  depends_on  = [aws_rds_cluster_instance.tfe]
}

output "aurora_aws_rds_cluster_endpoint" {
  value       = aws_rds_cluster.tfe.*.endpoint
  description = "Aurora DB cluster instance endpoint."
}

output "aws_db_instance_arn" {
  value       = aws_db_instance.tfe.*.arn
  description = "ARN of RDS DB instance."
}

output "aws_db_instance_endpoint" {
  value       = aws_db_instance.tfe.*.endpoint
  description = "RDS DB instance endpoint."
}


