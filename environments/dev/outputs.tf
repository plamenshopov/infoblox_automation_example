# Development Environment Outputs

output "infoblox_summary" {
  description = "Summary of Infoblox resources in dev environment"
  value       = module.infoblox.summary
}

output "networks" {
  description = "Created networks in dev environment"
  value       = module.infoblox.networks
}

output "dns_zones" {
  description = "Created DNS zones in dev environment"
  value       = module.infoblox.dns_zones
}

output "a_records" {
  description = "Created A records in dev environment"
  value       = module.infoblox.a_records
}

output "cname_records" {
  description = "Created CNAME records in dev environment"
  value       = module.infoblox.cname_records
}

output "host_records" {
  description = "Created host records in dev environment"
  value       = module.infoblox.host_records
}
