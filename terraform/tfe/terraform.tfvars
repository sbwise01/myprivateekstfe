friendly_name_prefix = "cloud-team"
common_tags = {
  "App"       = "TFE"
  "Env"       = "test"
  "Scenario"  = "alb-ext-r53-acm-ol"
  "Terraform" = "local-cli"
  "Owner"     = "BradWise"
}

vpc_cidr                = "10.11.0.0/16"
vpc_zones               = ["us-east-1a", "us-east-1b", "us-east-1c"]
vpc_public_subnets      = ["10.11.3.0/24", "10.11.4.0/24", "10.11.5.0/24"]
vpc_private_subnets     = ["10.11.0.0/24", "10.11.1.0/24", "10.11.2.0/24"]

tfe_bootstrap_bucket    = "bw-tfe-bootstrap-bucket-primary"
tfe_license_filepath    = "s3://bw-tfe-bootstrap-bucket-primary/tfe-license.rli"
tfe_release_sequence    = 652
tfe_hostname            = "console.tfe.aws.bradandmarsha.com"
console_password        = "MyConsolePassword123!"
enc_password            = "MyVaultPassword123!"
redis_password          = "MyRedisPassword123!"
tfe_install_secrets_arn = ""

log_forwarding_enabled = false
log_forwarding_type    = "cloudwatch"
s3_log_bucket_name     = "bw-tfe-bootstrap-bucket-primary"

ingress_cidr_443_allow       = ["192.30.252.0/22", "185.199.108.0/22", "140.82.112.0/20", "143.55.64.0/20", "98.97.11.160/32"]
ingress_agent_pool_443_allow = "sg-06256932174317e50"
egress_cidr_allow            = ["0.0.0.0/0"]
load_balancer_scheme         = "external"
create_tfe_alias_record      = true

asg_instance_count = 1
asg_max_size       = 1
os_distro          = "amzn2"

rds_password = "MyRdsPassword123!"
rds_multi_az = true
rds_engine_version = "11.15"
rds_skip_final_snapshot = true

enable_active_active = false
aws_ssm_enable       = true

ingress_cidr_8800_allow      = ["98.97.11.160/32"]
ingress_cidr_22_allow        = ["10.11.0.0/16", "98.97.11.160/32"]
ssh_key_pair                 = "bwise"
