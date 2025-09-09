# IPAM Module Outputs

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

output "network_containers" {
  description = "Created network container resources"
  value = {
    for k, v in infoblox_network_container.containers : k => {
      network_view = v.network_view
      cidr         = v.cidr
      comment      = v.comment
      ref          = v.ref
    }
  }
}

output "ip_allocations" {
  description = "Created IP allocation resources"
  value = {
    for k, v in infoblox_ip_allocation.allocations : k => {
      fqdn         = v.fqdn
      ip_addr      = v.ip_addr
      network_view = v.network_view
      comment      = v.comment
      ref          = v.ref
    }
  }
}
