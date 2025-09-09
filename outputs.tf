# Outputs for Infoblox Resources

# Network Outputs
output "networks" {
  description = "Created network resources"
  value = {
    for k, v in infoblox_network.networks : k => {
      network_view = v.network_view
      cidr         = v.cidr
      comment      = v.comment
      ref          = v.ref
    }
  }
}

# DNS Zone Outputs
output "dns_zones" {
  description = "Created DNS zone resources"
  value = {
    for k, v in infoblox_zone_auth.zones : k => {
      fqdn    = v.fqdn
      view    = v.view
      comment = v.comment
      ref     = v.ref
    }
  }
}

# A Record Outputs
output "a_records" {
  description = "Created A record resources"
  value = {
    for k, v in infoblox_a_record.a_records : k => {
      fqdn     = v.fqdn
      ip_addr  = v.ip_addr
      dns_view = v.dns_view
      ttl      = v.ttl
      comment  = v.comment
      ref      = v.ref
    }
  }
}

# CNAME Record Outputs
output "cname_records" {
  description = "Created CNAME record resources"
  value = {
    for k, v in infoblox_cname_record.cname_records : k => {
      alias     = v.alias
      canonical = v.canonical
      dns_view  = v.dns_view
      ttl       = v.ttl
      comment   = v.comment
      ref       = v.ref
    }
  }
}

# Host Record Outputs
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

# IP Allocation Outputs
output "ip_allocations" {
  description = "IP allocations for host records"
  value = {
    for k, v in infoblox_ip_allocation.host_ip_allocation : k => {
      fqdn         = v.fqdn
      ip_addr      = v.ip_addr
      network_view = v.network_view
      comment      = v.comment
      ref          = v.ref
    }
  }
}

# Summary Output
output "summary" {
  description = "Summary of all created resources"
  value = {
    environment    = var.environment
    project_name   = var.project_name
    networks_count = length(infoblox_network.networks)
    zones_count    = length(infoblox_zone_auth.zones)
    a_records_count = length(infoblox_a_record.a_records)
    cname_records_count = length(infoblox_cname_record.cname_records)
    host_records_count = length(infoblox_a_record.host_records)
    ip_allocations_count = length(infoblox_ip_allocation.host_ip_allocation)
  }
}
