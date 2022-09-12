variable "name_prefix" {
  type        = string
  description = "String value for name prefix for AWS resource names."
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for taggable AWS resources."
  default     = {}
}

variable "ebs_volume_type" {
  type        = string
  description = "The provisioned IOPS SSD volume type. Choose from `io1` or `io2`."
  default     = "io2"

  validation {
    condition     = contains(["io1", "io2"], var.ebs_volume_type)
    error_message = "Supported values are `io1` or `io2."
  }
}

variable "ebs_volume_size" {
  type        = number
  description = "The size of the boot volume for TFE agent instance. Must be at least `8` GB."
  default     = 16

  validation {
    condition = (
      var.ebs_volume_size >= 8 &&
      var.ebs_volume_size <= 16000
    )
    error_message = "The ebs volume must be greater `8` GB and lower than `16000` GB (16TB)."
  }
}

variable "ebs_iops" {
  type        = number
  description = "The amount of IOPS to provision for a `io1` or `io2`."
  default     = 8000

  validation {
    condition = (
      var.ebs_iops >= 100 &&
      var.ebs_iops <= 100000
    )
    error_message = "For io1 volumes, up to 50 IOPS per GiB. For io2 volumes, up to 500 IOPS per GiB."
  }
}

variable "instance_size" {
  type        = string
  description = "EC2 instance type for TFE Launch Template."
  default     = "m5.xlarge"
}

variable "kms_key_id" {
  type        = string
  description = "The KMS key ID to encrypt the boot volume."
  default     = null
}

variable "vpc_id" {
  type        = string
  description = "VPC ID that TFE Agent will be deployed into."
}

variable "egress_cidr_allow" {
  type        = list(string)
  description = "List of CIDR ranges to allow TFE instances egress to the internet, which it uses for package installs. Alternate option is to use AMIs with required packages pre-installed."
  default     = []
}

variable "asg_max_size" {
  type        = number
  description = "Max number of EC2 instances to run in Autoscaling Group."
  default     = 1
}

variable "asg_instance_count" {
  type        = number
  description = "Desired number of EC2 instances to run in Autoscaling Group."
  default     = 1
}

variable "ec2_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the EC2 instance. Private subnets is the best practice."
  default     = []
}

variable "tfc_address" {
  type        = string
  description = "The URL web address of TFE."
}

variable "tfc_agent_token" {
  type        = string
  description = "Agent token generated from the TFE."
}

variable "tfc_agent_name" {
  type        = string
  description = "The name of the TFE agent."
  default     = ""
}

variable "private_subnets_tag_key" {
  type        = string
  description = "The tag:key of private subnets."
  default     = "Name"
}

variable "private_subnets_tag_value" {
  type        = string
  description = "The value of private subnets tag."
  default     = "*private*"
}
