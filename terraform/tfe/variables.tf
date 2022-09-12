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

variable "tfe_release_sequence" {
  type        = number
  description = "TFE application version release sequence number within Replicated. Ignored if `airgap_install` is `true`."
  default     = 0
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

variable "tfe_hostname" {
  type        = string
  description = "Hostname/FQDN of TFE instance. This name should resolve to the load balancer DNS name and will be how users and systems access TFE."
}

variable "install_docker_before" {
  type        = bool
  description = "Boolean to install docker before TFE install script is called."
  default     = false
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Network
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "vpc_cidr" {
  type = string
  description = "The CIDR to use for VPC."
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "A list of subnet CIDRs for VPC to create public subnets with"
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "A list of subnet CIDRs for VPC to create private subnets with"
}

variable "vpc_zones" {
  type        = list(string)
  description = "A list of VPC zones to build subnets in"
}

variable "eks_cluster_name" {
  type = string
  description = "A cluster name used for VPC tagging for use by EKS module"
  default = "bwtest"
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

variable "create_tfe_alias_record" {
  type        = bool
  description = "Boolean to create Route53 Alias Record for `tfe_hostname` resolving to Load Balancer DNS name. If `true`, `route53_hosted_zone_tfe` is also required."
  default     = false
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Security
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "ingress_cidr_443_allow" {
  type        = list(string)
  description = "List of CIDR ranges to allow ingress traffic on port 443 to TFE server or load balancer."
  default     = ["0.0.0.0/0"]
}

variable "ingress_agent_pool_443_allow" {
  type        = string
  description = "List of Security Group ID's to allow ingress traffic on port 443 to TFE server or load balancer."
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

#-------------------------------------------------------------------------------------------------------------------------------------------
# External Services - RDS
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "rds_password" {
  type        = string
  description = "Password for RDS master DB user."
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Boolean for RDS to take a final snapshot."
  default     = false
}

variable "rds_engine_version" {
  type        = string
  description = "Version of RDS PostgreSQL."
  default     = "12.7"
}

variable "rds_multi_az" {
  type        = bool
  description = "Boolean to create a standby instance in a different AZ than the primary and enable HA."
  default     = true
}

#-------------------------------------------------------------------------------------------------------------------------------------------
# Redis
#-------------------------------------------------------------------------------------------------------------------------------------------
variable "enable_active_active" {
  type        = bool
  description = "Boolean to enable TFE Active/Active and in turn deploy Redis cluster."
  default     = false
}

variable "redis_password" {
  type        = string
  description = "Password (auth token) used to enable transit encryption (TLS) with Redis."
  default     = ""
}

