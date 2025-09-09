# Outputs for Unified Infoblox Module

# IPAM Outputs
output "networks" {
  description = "Created network resources"
  value       = module.ipam.networks
}

output "ip_allocations" {
  description = "Created IP allocation resources"
  value       = module.ipam.ip_allocations
}

# DNS Outputs
output "dns_zones" {
  description = "Created DNS zone resources"
  value       = module.dns.dns_zones
}

output "a_records" {
  description = "Created A record resources"
  value       = module.dns.a_records
}

output "cname_records" {
  description = "Created CNAME record resources"
  value       = module.dns.cname_records
}

# Host Records Output
output "host_records" {
  description = "Created host record resources"
  value = {
    for k, v in infoblox_a_record.host_records : k => {
      fqdn     = v.fqdn
      ip_addr  = v.ip_addr
      dns_view = v.dns_view
      ttl      = v.ttl
      comment  = v.comment
      ref      = v.ref
    }
  }
}

# Summary Output
output "summary" {
  description = "Summary of all created resources"
  value = {
    environment          = var.environment
    project_name         = var.project_name
    networks_count       = length(module.ipam.networks)
    dns_zones_count      = length(module.dns.dns_zones)
    a_records_count      = length(module.dns.a_records)
    cname_records_count  = length(module.dns.cname_records)
    host_records_count   = length(infoblox_a_record.host_records)
    ip_allocations_count = length(module.ipam.ip_allocations)
  }
}
