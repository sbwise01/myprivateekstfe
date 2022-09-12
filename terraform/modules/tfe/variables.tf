#-------------------------------------------------------------------------------------------------------------------------------------------
# Common
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "friendly_name_prefix" {
  type        = string
  description = "String value for friendly name prefix for AWS resource names."
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for taggable AWS resources."
  default     = {}
}

variable "is_secondary" {
  type        = bool
  description = "Boolean indicating whether TFE instance deployment is for Primary region or Secondary region."
  default     = false
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# TFE Installation Settings
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "tfe_bootstrap_bucket" {
  type        = string
  description = "Name of existing S3 bucket containing prerequisite files for TFE automated install. Typically would contain TFE license file and airgap files if `airgap_install` is `true`."
  default     = ""
}

variable "tfe_license_filepath" {
  type        = string
  description = "Full filepath of TFE license file (`.rli` file extension). A local filepath or S3 is supported. If s3, the path should start with `s3://`."
}

variable "airgap_install" {
  type        = bool
  description = "Boolean for TFE installation method to be airgap."
  default     = false
}

variable "replicated_bundle_path" {
  type        = string
  description = "Full path of Replicated bundle (`replicated.tar.gz`) in S3 bucket. A local filepath is not supported because the Replicated bundle is too large for user_data. Only specify if `airgap_install` is `true`. Should start with `s3://`."
  default     = ""
}

variable "tfe_airgap_bundle_path" {
  type        = string
  description = "Full path of TFE airgap bundle in S3 bucket. A local filepath is not supported because the airgap bundle is too large for user_data. Only specify if `airgap_install` is `true`. Should start with `s3://`."
  default     = ""
}

variable "tfe_release_sequence" {
  type        = number
  description = "TFE application version release sequence number within Replicated. Ignored if `airgap_install` is `true`."
  default     = 0
}

variable "tls_bootstrap_type" {
  type        = string
  description = "Defines where to terminate TLS/SSL. Set to `self-signed` to terminate at the load balancer, or `server-path` to terminate at the instance-level."
  default     = "self-signed"

  validation {
    condition     = contains(["self-signed", "server-path"], var.tls_bootstrap_type)
    error_message = "Supported values are `self-signed` or `server-path`."
  }
}

variable "tfe_cert_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for TFE server certificate in PEM format. Required if `tls_bootstrap_type` is `server-path`; otherwise ignored."
  default     = ""
}

variable "tfe_privkey_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for TFE private key in PEM format and base64 encoded. Required if `tls_bootstrap_type` is `server-path`; otherwise ignored."
  default     = ""
}

variable "ca_bundle_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for private/custom CA bundles. New lines must be replaced by `\n` character prior to storing as a plaintext secret."
  default     = ""
}

variable "tfe_install_secrets_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret metadata for TFE install secrets. If specified, secret must contain key/value pairs for `console_password`, and `enc_password`"
  default     = ""
}

variable "console_password" {
  type        = string
  description = "Password to unlock TFE Admin Console accessible via port 8800. Specify `aws_secretsmanager` to retrieve from AWS Secrets Manager via `tfe_install_secrets_arn` input."
  default     = "aws_secretsmanager"
}

variable "enc_password" {
  type        = string
  description = "Password to protect unseal key and root token of TFE embedded Vault. Specify `aws_secretsmanager` to retrieve from AWS Secrets Manager via `tfe_install_secrets_arn` input."
  default     = "aws_secretsmanager"
}

variable "remove_import_settings_from" {
  type        = bool
  description = "Replicated setting to automatically remove the `/etc/tfe-settings.json` file (referred to as `ImportSettingsFrom` by Replicated) after installation."
  default     = false
}

variable "tfe_hostname" {
  type        = string
  description = "Hostname/FQDN of TFE instance. This name should resolve to the load balancer DNS name and will be how users and systems access TFE."
}

variable "tbw_image" {
  type        = string
  description = "Terraform Build Worker container image to use. Set this to `custom_image` to use alternative container image."
  default     = "default_image"

  validation {
    condition     = contains(["default_image", "custom_image"], var.tbw_image)
    error_message = "Supported values are `default_image` or `custom_image`."
  }
}

variable "custom_tbw_ecr_repo" {
  type        = string
  description = "Name of AWS Elastic Container Registry (ECR) Repository where custom Terraform Build Worker (tbw) image exists. Only specify if `tbw_image` is set to `custom_image`."
  default     = ""
}

variable "custom_tbw_image_tag" {
  type        = string
  description = "Tag of custom Terraform Build Worker (tbw) image. Examples: `v1`, `latest`. Only specify if `tbw_image` is set to `custom_image`."
  default     = "latest"
}

variable "capacity_concurrency" {
  type        = string
  description = "Total concurrent Terraform Runs (Plans/Applies) allowed within TFE."
  default     = "10"
}

variable "capacity_memory" {
  type        = string
  description = "Maxium amount of memory (MB) that a Terraform Run (Plan/Apply) can consume within TFE."
  default     = "512"
}

variable "enable_metrics_collection" {
  type        = bool
  description = "Boolean to enable internal TFE metrics collection."
  default     = true
}

variable "metrics_endpoint_enabled" {
  type        = bool
  description = "Boolean to enable the TFE metrics endpoint."
  default     = false
}

variable "metrics_endpoint_port_http" {
  type        = number
  description = "Defines the TCP port on which HTTP metrics requests will be handled"
  default     = 9090
}

variable "metrics_endpoint_port_https" {
  type        = number
  description = "Defines the TCP port on which HTTPS metrics requests will be handled"
  default     = 9091
}

variable "metrics_endpoint_allow_cidr" {
  description = "The CIDR to allow access to the metrics endpoint of TFE"
  default     = null
}

variable "metrics_endpoint_allow_sg" {
  description = "The Security Groups to allow access to the metrics endpoint"
  default     = null
}

variable "force_tls" {
  type        = bool
  description = "Boolean to require all internal TFE application traffic to use HTTPS by sending a 'Strict-Transport-Security' header value in responses, and marking cookies as secure. Only enable if `tls_bootstrap_type` is `server-path`."
  default     = false
}

variable "restrict_worker_metadata_access" {
  type        = bool
  description = "Boolean to block Terraform build worker containers from being able to access the EC2 instance metadata endpoint."
  default     = false
}

variable "pkg_repos_reachable_with_airgap" {
  type        = bool
  description = "Boolean to install prereq software dependencies if airgapped. Only valid when `airgap_install` is `true`."
  default     = false
}

variable "install_docker_before" {
  type        = bool
  description = "Boolean to install docker before TFE install script is called."
  default     = false
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Network
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "vpc_id" {
  type        = string
  description = "VPC ID that TFE will be deployed into."
}

variable "lb_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the load balancer. If LB is external, these should be public subnets."
  default     = []
}

variable "ec2_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the EC2 instance. Private subnets is the best practice."
  default     = []
}

variable "load_balancer_type" {
  type        = string
  description = "String indicating whether the load balancer deployed is an Application Load Balancer (alb) or Network Load Balancer (nlb)."
  default     = "alb"

  validation {
    condition     = contains(["alb", "nlb"], var.load_balancer_type)
    error_message = "Supported values are `alb` or `nlb`."
  }
}

variable "load_balancer_scheme" {
  type        = string
  description = "Load balancer exposure. Specify `external` if load balancer is to be public/external-facing, or `internal` if load balancer is to be private/internal-facing."
  default     = "external"

  validation {
    condition     = var.load_balancer_scheme == "external" || var.load_balancer_scheme == "internal"
    error_message = "Supported values are `external` or `internal`."
  }
}

variable "http_proxy" {
  type        = string
  description = "Proxy address to configure for TFE to use for outbound connections/requests."
  default     = ""
}

variable "extra_no_proxy" {
  type        = string
  description = "A comma-separated string of hostnames or IP addresses to add to the TFE no_proxy list. Only specify if a value for `http_proxy` is also specified."
  default     = ""
}

variable "log_forwarding_enabled" {
  type        = bool
  description = "Boolean to enable TFE log forwarding at the application level."
  default     = false
}

variable "log_forwarding_type" {
  type        = string
  description = "Which type of log forwarding to configure. For any of these,`var.log_forwarding_enabled` must be set to `true`. For  S3, specify `s3` and supply a value for `var.s3_log_bucket_name`, for Cloudwatch specify `cloudwatch` and `var.cloudwatch_log_group_name`, for custom, specify `custom` and supply a valid fluentbit config in `var.custom_fluent_bit_config`"
  default     = "s3"

  validation {
    condition     = contains(["s3", "cloudwatch", "custom"], var.log_forwarding_type)
    error_message = "Supported values are `s3`, `cloudwatch` or `custom`."
  }
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "Name of CloudWatch Log Group to configure as log forwarding destination. `log_forwarding_enabled` must also be `true`."
  default     = ""
}

variable "s3_log_bucket_name" {
  type        = string
  description = "Name of bucket to configure as log forwarding destination. `log_forwarding_enabled` must also be `true`."
  default     = ""
}

variable "custom_fluent_bit_config" {
  type        = string
  description = "A custom FluentBit config for TFE logging"
  default     = null
}

variable "hairpin_addressing" {
  type        = bool
  description = "Boolean to enable TFE services to direct requests to the servers' internal IP address rather than the TFE hostname/FQDN. Only enable if `tls_bootstrap_type` is `server-path`."
  default     = false
}

variable "tfe_tls_certificate_arn" {
  type        = string
  description = "ARN of TFE certificate imported in ACM to be used for Application Load Balancer HTTPS listeners. Required if `route53_hosted_zone_acm` is not specified."
  default     = null
}

variable "route53_hosted_zone_acm" {
  type        = string
  description = "Route53 Hosted Zone name to create ACM Certificate Validation CNAME record in. Required if `tls_certificate_arn` is not specified."
  default     = null
}

variable "create_tfe_alias_record" {
  type        = bool
  description = "Boolean to create Route53 Alias Record for `tfe_hostname` resolving to Load Balancer DNS name. If `true`, `route53_hosted_zone_tfe` is also required."
  default     = false
}

variable "route53_hosted_zone_tfe" {
  type        = string
  description = "Route53 Hosted Zone name to create `tfe_hostname` Alias record in. Required if `create_tfe_alias_record` is `true`."
  default     = null
}

variable "tfe_hosted_zone_is_private" {
  type        = bool
  description = "Boolean indicating if `route53_hosted_zone_tfe` is a private zone."
  default     = false
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Security
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "ingress_cidr_443_allow" {
  type        = list(string)
  description = "List of CIDR ranges to allow ingress traffic on port 443 to TFE server or load balancer."
  default     = []
}

variable "ingress_agent_pool_443_allow" {
  type        = string
  description = "Agent pool security group ID to allow ingress traffic on port 443 to TFE server or load balancer."
  default     = null
}

variable "ingress_cidr_8800_allow" {
  type        = list(string)
  description = "List of CIDR ranges to allow ingress traffic on port 8800 to TFE management console."
  default     = []
}

variable "ingress_cidr_22_allow" {
  type        = list(string)
  description = "List of CIDR ranges to allow SSH ingress to TFE EC2 instance (i.e. bastion host IP, workstation IP, etc.)."
  default     = []
}

variable "egress_cidr_allow" {
  type        = list(string)
  description = "List of CIDR ranges to allow TFE instances egress to the internet, which it uses for package installs. Alternate option is to use AMIs with required packages pre-installed."
  default     = []
}

variable "ssh_key_pair" {
  type        = string
  description = "Name of existing SSH key pair to attach to TFE EC2 instance."
  default     = ""
}

variable "aws_ssm_enable" {
  type        = bool
  description = "Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the TFE role, allowing the SSM agent (if present) to function."
  default     = false
}

variable "alb_ssl_policy" {
  type        = string
  description = "The SSL policy to use for TLS listeners"
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Compute
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "os_distro" {
  type        = string
  description = "Linux OS distribution for TFE EC2 instance. Choose from `amzn2`, `ubuntu`, `rhel`, `centos`."
  default     = "amzn2"

  validation {
    condition     = contains(["amzn2", "ubuntu", "rhel", "centos"], var.os_distro)
    error_message = "Supported values are `amzn2`, `ubuntu`, `rhel` or `centos`."
  }
}

variable "asg_instance_count" {
  type        = number
  description = "Desired number of EC2 instances to run in Autoscaling Group. Leave at `1` unless Active/Active is enabled."
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "Max number of EC2 instances to run in Autoscaling Group. Increase after Active/Active is enabled."
  default     = 1
}

variable "asg_health_check_grace_period" {
  type        = number
  description = "The amount of time to wait for a new TFE instance to be healthy. If this threshold is breached, the ASG will terminate the instance and launch a new one."
  default     = 900
}

variable "ami_id" {
  type        = string
  description = "Custom AMI ID for TFE EC2 Launch Template. If specified, value of `os_distro` must coincide with this custom AMI OS distro."
  default     = null

  validation {
    condition     = try((length(var.ami_id) > 4 && substr(var.ami_id, 0, 4) == "ami-"), var.ami_id == null)
    error_message = "The ami_id value must start with \"ami-\"."
  }
}

variable "instance_size" {
  type        = string
  description = "EC2 instance type for TFE Launch Template."
  default     = "m5.xlarge"
}

# For now only allowing gp3 which is cheaper and faster. There is an issue with the AWS provider switching between gp2 and gp3  
# as the iops and throughput are not being set to null when they are not needed for gp2 when switching between them.
variable "ebs_volume_type" {
  type        = string
  description = "The volume type. Choose from `gp3`."
  default     = "gp3"

  validation {
    condition     = contains(["gp3", ], var.ebs_volume_type)
    error_message = "Supported values are `gp3`."
  }
}

variable "ebs_volume_size" {
  type        = number
  description = "The size of the boot volume for TFE type. Must be at least `50` GB."
  default     = 50

  validation {
    condition = (
      var.ebs_volume_size >= 50 &&
      var.ebs_volume_size <= 16000
    )
    error_message = "The ebs volume must be greater `50` GB and lower than `16000` GB (16TB)."
  }
}

variable "ebs_throughput" {
  type        = number
  description = "The throughput to provision for a `gp3` volume in MB/s. Must be at least `125` MB/s."
  default     = 125

  validation {
    condition = (
      var.ebs_throughput >= 125 &&
      var.ebs_throughput <= 1000
    )
    error_message = "The throughput must be at least `125` MB/s and lower than `1000` MB/s."
  }
}

variable "ebs_iops" {
  type        = number
  description = "The amount of IOPS to provision for a `gp3` volume. Must be at least `3000`."
  default     = 3000

  validation {
    condition = (
      var.ebs_iops >= 3000 &&
      var.ebs_iops <= 16000
    )
    error_message = "The IOPS must be at least `3000` GB and lower than `16000` (16TB)."
  }
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# External Services - RDS
#-------------------------------------------------------------------------------------------------------------------------------------------
### --- Common --- ###
variable "rds_is_aurora" {
  type        = bool
  description = "Boolean for deploying global Amazon Aurora PostgreSQL instead of Amazon RDS for PostgreSQL"
  default     = false
}

variable "rds_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for RDS Database Subnet Group. Private subnets is the best practice."
  default     = []
}

variable "rds_database_name" {
  type        = string
  description = "Name of database."
  default     = "tfe"
}

variable "rds_username" {
  type        = string
  description = "Username for the master DB user."
  default     = "tfe"
}

variable "rds_password" {
  type        = string
  description = "Password for RDS master DB user."
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Boolean for RDS to take a final snapshot."
  default     = false
}

variable "rds_preferred_backup_window" {
  type        = string
  description = "Daily time range (UTC) for RDS backup to occur. Must not overlap with `rds_preferred_maintenance_window` if specified."
  default     = "04:00-04:30"
}

variable "rds_backup_retention_period" {
  type        = number
  description = "The number of days to retain backups for. Must be between 0 and 35. Must be greater than 0 if the database is used as a source for a Read Replica."
  default     = 35
}

variable "rds_preferred_maintenance_window" {
  type        = string
  description = "Window (UTC) to perform RDS database maintenance. Must not overlap with `rds_preferred_backup_window` if specified."
  default     = "Sun:08:00-Sun:09:00"
}

### --- RDS --- ###
variable "rds_engine_version" {
  type        = string
  description = "Version of RDS PostgreSQL."
  default     = "12.7"
}

variable "rds_instance_class" {
  type        = string
  description = "Instance class of RDS PostgreSQL database."
  default     = "db.m5.xlarge"
}

variable "rds_copy_tags_to_snapshot" {
  type        = bool
  description = "Boolean to enable copying tags to RDS snapshot."
  default     = true
}

variable "rds_allow_major_version_upgrade" {
  type        = bool
  description = "Boolean to allow major version upgrades of the database."
  default     = false
}

variable "rds_auto_minor_version_upgrade" {
  type        = bool
  description = "Boolean to enable the automatic upgrading of new minor versions during the specified `rds_preferred_maintenance_window`."
  default     = true
}

variable "rds_deletion_protection" {
  type        = bool
  description = "Boolean to proctect the database from being deleted. The database cannot be deleted when `true`."
  default     = false
}

variable "rds_allocated_storage" {
  type        = string
  description = "Size capacity (GB) of RDS PostgreSQL database."
  default     = "50"
}

variable "rds_multi_az" {
  type        = bool
  description = "Boolean to create a standby instance in a different AZ than the primary and enable HA."
  default     = true
}

### --- Aurora --- ###
variable "aurora_rds_engine_version" {
  type        = number
  description = "Engine version of Aurora PostgreSQL."
  default     = 12.4
}

variable "aurora_rds_instance_class" {
  type        = string
  description = "Instance class of Aurora PostgreSQL database."
  default     = "db.r5.xlarge"
}

variable "aurora_rds_availability_zones" {
  type        = list(string)
  description = "List of Availability Zones to spread Aurora DB cluster across."
  default     = null
}

variable "aurora_rds_engine_mode" {
  type        = string
  description = "Aurora engine mode."
  default     = "provisioned"
}

variable "aurora_rds_replica_count" {
  type        = number
  description = "Amount of Aurora Replica instances to deploy within the Aurora DB cluster within the same region."
  default     = 1
}

variable "aurora_rds_replication_source_identifier" {
  type        = string
  description = "ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica. Intended to be used by Aurora Replica in Secondary region."
  default     = null
}

variable "aurora_rds_global_cluster_id" {
  type        = string
  description = "Aurora Global Database cluster identifier. Intended to be used by Aurora DB Cluster instance in Secondary region."
  default     = null
}

variable "aurora_source_region" {
  type        = string
  description = "Source region for Aurora Cross-Region Replication. Only specify for Secondary instance."
  default     = null
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# External Services - S3
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "bucket_replication_configuration" {
  description = "Map containing S3 Cross-Region Replication configuration."
  type        = any
  default     = {}
}

variable "destination_bucket" {
  type        = string
  description = "Destination S3 Bucket for Cross-Region Replication configuration. Should exist in Secondary region."
  default     = ""
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Redis
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "enable_active_active" {
  type        = bool
  description = "Boolean to enable TFE Active/Active and in turn deploy Redis cluster."
  default     = false
}

variable "redis_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for Redis cluster subnet group."
  default     = null
}

variable "redis_engine_version" {
  type        = string
  description = "Redis version number"
  default     = "5.0.6"
}

variable "redis_port" {
  type        = number
  description = "Port number the Redis nodes will accept connections on."
  default     = 6379
}

variable "redis_parameter_group_name" {
  type        = string
  description = "Name of parameter group to associate with Redis cluster."
  default     = "default.redis5.0"
}

variable "redis_node_type" {
  type        = string
  description = "Type of Redis node from a compute, memory, and network throughput standpoint."
  default     = "cache.m4.large"
}

variable "redis_replica_count" {
  type        = number
  description = "Number of replica nodes in Redis cluster."
  default     = 1
}

variable "redis_multi_az_enabled" {
  type        = bool
  description = "Boolean for deploying Redis nodes in multiple Availability Zones and enabling automatic failover."
  default     = true
}

variable "redis_password" {
  type        = string
  description = "Password (auth token) used to enable transit encryption (TLS) with Redis."
  default     = ""
}

