# Infoblox Provider Variables
variable "infoblox_username" {
  description = "Username for Infoblox NIOS"
  type        = string
  sensitive   = true
}

variable "infoblox_password" {
  description = "Password for Infoblox NIOS"
  type        = string
  sensitive   = true
}

variable "infoblox_server" {
  description = "Infoblox NIOS server hostname or IP"
  type        = string
}

variable "infoblox_ssl_verify" {
  description = "SSL verification mode for Infoblox connection"
  type        = bool
  default     = true
}

# Environment Variables
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "infoblox-automation"
}

# Network Configuration Variables
variable "network_configs" {
  description = "Network configurations to be created"
  type = map(object({
    network_view = string
    network      = string
    comment      = string
    ea_tags      = optional(map(string), {})
  }))
  default = {}
}

# DNS Zone Configuration Variables
variable "dns_zones" {
  description = "DNS zones to be created"
  type = map(object({
    zone         = string
    view         = string
    zone_format  = optional(string, "FORWARD")
    comment      = optional(string, "")
    ea_tags      = optional(map(string), {})
  }))
  default = {}
}

# A Record Configuration Variables
variable "a_records" {
  description = "A records to be created"
  type = map(object({
    fqdn    = string
    ip_addr = string
    view    = optional(string, "default")
    ttl     = optional(number, 3600)
    comment = optional(string, "")
    ea_tags = optional(map(string), {})
  }))
  default = {}
}

# CNAME Record Configuration Variables
variable "cname_records" {
  description = "CNAME records to be created"
  type = map(object({
    alias     = string
    canonical = string
    view      = optional(string, "default")
    ttl       = optional(number, 3600)
    comment   = optional(string, "")
    ea_tags   = optional(map(string), {})
  }))
  default = {}
}

# Host Record Configuration Variables
variable "host_records" {
  description = "Host records to be created"
  type = map(object({
    fqdn      = string
    ip_addr   = optional(string, "")
    network   = optional(string, "")
    allocate_ip = optional(bool, false)
    view      = optional(string, "default")
    ttl       = optional(number, 3600)
    comment   = optional(string, "")
    ea_tags   = optional(map(string), {})
  }))
  default = {}
}
