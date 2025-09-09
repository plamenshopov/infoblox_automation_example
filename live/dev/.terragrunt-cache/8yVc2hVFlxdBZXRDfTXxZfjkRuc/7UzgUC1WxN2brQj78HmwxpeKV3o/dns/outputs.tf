# DNS Module Outputs

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

output "ptr_records" {
  description = "Created PTR record resources"
  value = {
    for k, v in infoblox_ptr_record.ptr_records : k => {
      ptrdname = v.ptrdname
      ip_addr  = v.ip_addr
      dns_view = v.dns_view
      ttl      = v.ttl
      comment  = v.comment
      ref      = v.ref
    }
  }
}

output "mx_records" {
  description = "Created MX record resources"
  value = {
    for k, v in infoblox_mx_record.mx_records : k => {
      fqdn           = v.fqdn
      mail_exchanger = v.mail_exchanger
      preference     = v.preference
      dns_view       = v.dns_view
      ttl            = v.ttl
      comment        = v.comment
      ref            = v.ref
    }
  }
}
