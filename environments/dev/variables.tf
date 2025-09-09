# Development Environment Variables

variable "infoblox_username" {
  description = "Username for Infoblox NIOS (dev environment)"
  type        = string
  sensitive   = true
}

variable "infoblox_password" {
  description = "Password for Infoblox NIOS (dev environment)"
  type        = string
  sensitive   = true
}

variable "infoblox_server" {
  description = "Infoblox NIOS server hostname or IP (dev environment)"
  type        = string
}

variable "infoblox_ssl_verify" {
  description = "SSL verification mode for Infoblox connection"
  type        = bool
  default     = false  # Often disabled in dev environments
}
