# Staging Environment Configuration

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "infoblox/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

module "infoblox" {
  source = "../../"

  # Environment Configuration
  environment  = "staging"
  project_name = "infoblox-automation"

  # Infoblox Provider Configuration
  infoblox_username   = var.infoblox_username
  infoblox_password   = var.infoblox_password
  infoblox_server     = var.infoblox_server
  infoblox_ssl_verify = var.infoblox_ssl_verify

  # Load configurations from local files
  network_configs = local.network_configs
  dns_zones      = local.dns_zones
  a_records      = local.a_records
  cname_records  = local.cname_records
  host_records   = local.host_records
}

# Local values for configurations
locals {
  # Load network configurations from YAML files
  network_configs = yamldecode(file("${path.module}/configs/networks.yaml"))

  # Load DNS zone configurations
  dns_zones = yamldecode(file("${path.module}/configs/dns-zones.yaml"))

  # Load A record configurations
  a_records = yamldecode(file("${path.module}/configs/a-records.yaml"))

  # Load CNAME record configurations
  cname_records = yamldecode(file("${path.module}/configs/cname-records.yaml"))

  # Load host record configurations
  host_records = yamldecode(file("${path.module}/configs/host-records.yaml"))
}
