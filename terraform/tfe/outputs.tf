output "tfe_url" {
  value = module.tfe.url
}

output "tfe_admin_console_url" {
  value = module.tfe.admin_console_url
}

output "tfe_lb_dns_name" {
  value = module.tfe.lb_dns_name
}

output "tfe_s3_bucket_name" {
  value = module.tfe.s3_bucket_name
}
