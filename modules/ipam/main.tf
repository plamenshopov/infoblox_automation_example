# IPAM Module - Network Management
# This module handles network-related resources in Infoblox

terraform {
  required_providers {
    infoblox = {
      source  = "infobloxopen/infoblox"
      version = "~> 2.0"
    }
  }
}

# Network Resources
resource "infoblox_network" "networks" {
  for_each = var.networks

  network_view = each.value.network_view
  cidr         = each.value.cidr
  comment      = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    var.default_tags,
    {
      Name = each.key
    }
  ))
}

# Network Container Resources
resource "infoblox_network_container" "containers" {
  for_each = var.network_containers

  network_view = each.value.network_view
  cidr         = each.value.cidr
  comment      = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    var.default_tags,
    {
      Name = each.key
    }
  ))
}

# IP Allocation Resources
resource "infoblox_ip_allocation" "allocations" {
  for_each = var.ip_allocations

  fqdn         = each.value.fqdn
  network_view = each.value.network_view
  comment      = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    var.default_tags,
    {
      Name = each.key
    }
  ))
}
