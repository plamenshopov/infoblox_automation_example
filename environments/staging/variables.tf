# Staging Environment Variables

variable "infoblox_username" {
  description = "Username for Infoblox NIOS (staging environment)"
  type        = string
  sensitive   = true
}

variable "infoblox_password" {
  description = "Password for Infoblox NIOS (staging environment)"
  type        = string
  sensitive   = true
}

variable "infoblox_server" {
  description = "Infoblox NIOS server hostname or IP (staging environment)"
  type        = string
}

variable "infoblox_ssl_verify" {
  description = "SSL verification mode for Infoblox connection"
  type        = bool
  default     = true  # SSL verification enabled in staging
}
