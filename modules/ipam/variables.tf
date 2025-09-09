# IPAM Module Variables

variable "networks" {
  description = "Network configurations"
  type = map(object({
    network_view = string
    cidr         = string
    comment      = string
    ea_tags      = optional(map(string), {})
  }))
  default = {}
}

variable "network_containers" {
  description = "Network container configurations"
  type = map(object({
    network_view = string
    cidr         = string
    comment      = string
    ea_tags      = optional(map(string), {})
  }))
  default = {}
}

variable "ip_allocations" {
  description = "IP allocation configurations"
  type = map(object({
    fqdn         = string
    network_view = string
    comment      = string
    ea_tags      = optional(map(string), {})
  }))
  default = {}
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}
