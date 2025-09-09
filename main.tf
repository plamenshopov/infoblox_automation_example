# Main Terraform Configuration for Infoblox Resources

# Networks
resource "infoblox_network" "networks" {
  for_each = var.network_configs

  network_view = each.value.network_view
  cidr         = each.value.network
  comment      = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Name        = each.key
    }
  ))
}

# DNS Zones
resource "infoblox_zone_auth" "zones" {
  for_each = var.dns_zones

  fqdn    = each.value.zone
  view    = each.value.view
  comment = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Name        = each.key
    }
  ))
}

# A Records
resource "infoblox_a_record" "a_records" {
  for_each = var.a_records

  fqdn    = each.value.fqdn
  ip_addr = each.value.ip_addr
  dns_view = each.value.view
  ttl     = each.value.ttl
  comment = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Name        = each.key
    }
  ))
}

# CNAME Records
resource "infoblox_cname_record" "cname_records" {
  for_each = var.cname_records

  alias     = each.value.alias
  canonical = each.value.canonical
  dns_view  = each.value.view
  ttl       = each.value.ttl
  comment   = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Name        = each.key
    }
  ))
}

# IP Allocation for Host Records
resource "infoblox_ip_allocation" "host_ip_allocation" {
  for_each = {
    for k, v in var.host_records : k => v
    if v.allocate_ip && v.network != ""
  }

  fqdn         = each.value.fqdn
  network_view = "default"
  comment      = "IP allocation for ${each.value.fqdn}"

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Name        = each.key
      Type        = "auto-allocated"
    }
  ))
}

# Host Records (A Records with potential IP allocation)
resource "infoblox_a_record" "host_records" {
  for_each = var.host_records

  fqdn     = each.value.fqdn
  ip_addr  = each.value.allocate_ip ? infoblox_ip_allocation.host_ip_allocation[each.key].ip_addr : each.value.ip_addr
  dns_view = each.value.view
  ttl      = each.value.ttl
  comment  = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Name        = each.key
      Type        = each.value.allocate_ip ? "auto-allocated" : "static"
    }
  ))

  depends_on = [infoblox_ip_allocation.host_ip_allocation]
}
