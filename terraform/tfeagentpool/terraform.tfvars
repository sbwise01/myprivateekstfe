name_prefix = "cloud-team"
common_tags = {
  "App"       = "TFE"
  "Env"       = "test"
  "Scenario"  = "tfe-agent-instance"
  "Terraform" = "local-cli"
  "Owner"     = "BradWise"
}

vpc_id                    = "vpc-08f00de227dc61844"
private_subnets_tag_key   = "kubernetes.io/role/internal-elb"
private_subnets_tag_value = "1"
egress_cidr_allow         = ["0.0.0.0/0"]

tfc_address     = "https://console.tfe.aws.bradandmarsha.com"
tfc_agent_name  = "bradtest"
tfc_agent_token = "zAgKJ7WOS5MjJw.atlasv1.50LwZzg04zzJ27354NtlJ5QhmVqqe4yUObLI8gAqncQf8cq2aVJRkdHIygUh0eqliIA"
