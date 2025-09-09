# Terraform and Provider Version Constraints
terraform {
  required_version = ">= 1.0"

  required_providers {
    infoblox = {
      source  = "infobloxopen/infoblox"
      version = "~> 2.0"
    }
  }

  # Backend configuration - customize based on your needs
  backend "s3" {
    # bucket         = "your-terraform-state-bucket"
    # key            = "infoblox/terraform.tfstate"
    # region         = "us-east-1"
    # encrypt        = true
    # dynamodb_table = "terraform-lock"
  }
}

# Infoblox Provider Configuration
provider "infoblox" {
  username = var.infoblox_username
  password = var.infoblox_password
  server   = var.infoblox_server
  sslmode  = var.infoblox_ssl_verify
  
  # Connection pool settings
  connect_timeout = 60
  pool_connections = 10
}
