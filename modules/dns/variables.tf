# DNS Module Variables

variable "dns_zones" {
  description = "DNS zone configurations"
  type = map(object({
    fqdn    = string
    view    = string
    comment = string
    ea_tags = optional(map(string), {})
  }))
  default = {}
}

variable "a_records" {
  description = "A record configurations"
  type = map(object({
    fqdn    = string
    ip_addr = string
    view    = string
    ttl     = number
    comment = string
    ea_tags = optional(map(string), {})
  }))
  default = {}
}

variable "cname_records" {
  description = "CNAME record configurations"
  type = map(object({
    alias     = string
    canonical = string
    view      = string
    ttl       = number
    comment   = string
    ea_tags   = optional(map(string), {})
  }))
  default = {}
}

variable "ptr_records" {
  description = "PTR record configurations"
  type = map(object({
    ptrdname = string
    ip_addr  = string
    view     = string
    ttl      = number
    comment  = string
    ea_tags  = optional(map(string), {})
  }))
  default = {}
}

variable "mx_records" {
  description = "MX record configurations"
  type = map(object({
    fqdn           = string
    mail_exchanger = string
    preference     = number
    view           = string
    ttl            = number
    comment        = string
    ea_tags        = optional(map(string), {})
  }))
  default = {}
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}
