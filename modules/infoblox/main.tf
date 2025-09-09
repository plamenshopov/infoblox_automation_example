# Unified Infoblox Module - Terragrunt Version
# This module handles all Infoblox resources using local file configurations

# Local values to load YAML configurations
locals {
  config_path = var.config_files_path
  
  # Load all configuration files
  networks_raw      = fileexists("${local.config_path}/networks.yaml") ? yamldecode(file("${local.config_path}/networks.yaml")) : {}
  dns_zones_raw     = fileexists("${local.config_path}/dns-zones.yaml") ? yamldecode(file("${local.config_path}/dns-zones.yaml")) : {}
  a_records_raw     = fileexists("${local.config_path}/a-records.yaml") ? yamldecode(file("${local.config_path}/a-records.yaml")) : {}
  cname_records_raw = fileexists("${local.config_path}/cname-records.yaml") ? yamldecode(file("${local.config_path}/cname-records.yaml")) : {}
  host_records_raw  = fileexists("${local.config_path}/host-records.yaml") ? yamldecode(file("${local.config_path}/host-records.yaml")) : {}
  
  # Process configurations with defaults
  networks = {
    for k, v in local.networks_raw : k => {
      network_view = try(v.network_view, "default")
      network      = v.network
      comment      = try(v.comment, "")
      ea_tags      = merge(var.default_tags, try(v.ea_tags, {}))
    }
  }
  
  dns_zones = {
    for k, v in local.dns_zones_raw : k => {
      zone    = v.zone
      view    = try(v.view, "default")
      comment = try(v.comment, "")
      ea_tags = merge(var.default_tags, try(v.ea_tags, {}))
    }
  }
  
  a_records = {
    for k, v in local.a_records_raw : k => {
      fqdn    = v.fqdn
      ip_addr = v.ip_addr
      view    = try(v.view, "default")
      ttl     = try(v.ttl, 3600)
      comment = try(v.comment, "")
      ea_tags = merge(var.default_tags, try(v.ea_tags, {}))
    }
  }
  
  cname_records = {
    for k, v in local.cname_records_raw : k => {
      alias     = v.alias
      canonical = v.canonical
      view      = try(v.view, "default")
      ttl       = try(v.ttl, 3600)
      comment   = try(v.comment, "")
      ea_tags   = merge(var.default_tags, try(v.ea_tags, {}))
    }
  }
  
  host_records = {
    for k, v in local.host_records_raw : k => {
      fqdn        = v.fqdn
      ip_addr     = try(v.ip_addr, "")
      network     = try(v.network, "")
      allocate_ip = try(v.allocate_ip, false)
      view        = try(v.view, "default")
      ttl         = try(v.ttl, 3600)
      comment     = try(v.comment, "")
      ea_tags     = merge(var.default_tags, try(v.ea_tags, {}))
    }
  }
}

# Use the existing IPAM module
module "ipam" {
  source = "../ipam"
  
  networks        = local.networks
  default_tags    = var.default_tags
  ip_allocations  = {
    for k, v in local.host_records : k => {
      fqdn         = v.fqdn
      network_view = "default"
      comment      = v.comment
      ea_tags      = v.ea_tags
    } if v.allocate_ip && v.network != ""
  }
}

# Use the existing DNS module
module "dns" {
  source = "../dns"
  
  dns_zones     = local.dns_zones
  a_records     = local.a_records
  cname_records = local.cname_records
  default_tags  = var.default_tags
}

# Host Records (A Records with potential IP allocation)
resource "infoblox_a_record" "host_records" {
  for_each = local.host_records

  fqdn     = each.value.fqdn
  ip_addr  = each.value.allocate_ip ? module.ipam.ip_allocations[each.key].ip_addr : each.value.ip_addr
  dns_view = each.value.view
  ttl      = each.value.ttl
  comment  = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    {
      Name = each.key
      Type = each.value.allocate_ip ? "auto-allocated" : "static"
    }
  ))

  depends_on = [module.ipam]
}
