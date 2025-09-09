# DNS Module - DNS Record Management
# This module handles DNS-related resources in Infoblox

terraform {
  required_providers {
    infoblox = {
      source  = "infobloxopen/infoblox"
      version = "~> 2.0"
    }
  }
}

# DNS Zone Resources
resource "infoblox_zone_auth" "zones" {
  for_each = var.dns_zones

  fqdn    = each.value.fqdn
  view    = each.value.view
  comment = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    var.default_tags,
    {
      Name = each.key
    }
  ))
}

# A Record Resources
resource "infoblox_a_record" "a_records" {
  for_each = var.a_records

  fqdn     = each.value.fqdn
  ip_addr  = each.value.ip_addr
  dns_view = each.value.view
  ttl      = each.value.ttl
  comment  = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    var.default_tags,
    {
      Name = each.key
    }
  ))
}

# CNAME Record Resources
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
    var.default_tags,
    {
      Name = each.key
    }
  ))
}

# PTR Record Resources
resource "infoblox_ptr_record" "ptr_records" {
  for_each = var.ptr_records

  ptrdname = each.value.ptrdname
  ip_addr  = each.value.ip_addr
  dns_view = each.value.view
  ttl      = each.value.ttl
  comment  = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    var.default_tags,
    {
      Name = each.key
    }
  ))
}

# MX Record Resources
resource "infoblox_mx_record" "mx_records" {
  for_each = var.mx_records

  fqdn       = each.value.fqdn
  mail_exchanger = each.value.mail_exchanger
  preference = each.value.preference
  dns_view   = each.value.view
  ttl        = each.value.ttl
  comment    = each.value.comment

  # Extensible attributes
  ext_attrs = jsonencode(merge(
    each.value.ea_tags,
    var.default_tags,
    {
      Name = each.key
    }
  ))
}
