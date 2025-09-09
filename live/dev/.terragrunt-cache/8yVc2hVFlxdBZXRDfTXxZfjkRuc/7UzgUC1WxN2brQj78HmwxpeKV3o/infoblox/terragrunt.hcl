# Development Environment Terragrunt Configuration

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Reference the infoblox module
terraform {
  source = "../../modules//infoblox"
}

# Environment-specific inputs
inputs = {
  environment = "dev"
  
  # Infoblox connection for dev
  infoblox_server     = "infoblox-dev.company.com"
  infoblox_ssl_verify = false  # Often disabled in dev
  
  # Load configurations from YAML files
  config_files_path = "${get_terragrunt_dir()}/configs"
  
  # Environment-specific tags
  default_tags = {
    Environment   = "dev"
    ManagedBy     = "terragrunt"
    Project       = "infoblox-automation"
    CostCenter    = "engineering"
    Owner         = "platform-team"
  }
}
