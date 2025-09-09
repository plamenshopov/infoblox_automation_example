# Staging Environment Terragrunt Configuration

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Reference the infoblox module
terraform {
  source = "../../modules//infoblox"
}

# Dependency on dev environment (optional - for learning from dev configs)
dependency "dev" {
  config_path = "../dev"
  skip_outputs = true
  
  # Mock outputs for planning
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    summary = {
      environment = "dev"
    }
  }
}

# Environment-specific inputs
inputs = {
  environment = "staging"
  
  # Infoblox connection for staging
  infoblox_server     = "infoblox-staging.company.com"
  infoblox_ssl_verify = true  # SSL enabled in staging
  
  # Load configurations from YAML files
  config_files_path = "${get_terragrunt_dir()}/configs"
  
  # Environment-specific tags
  default_tags = {
    Environment   = "staging"
    ManagedBy     = "terragrunt"
    Project       = "infoblox-automation"
    CostCenter    = "engineering"
    Owner         = "platform-team"
    Backup        = "daily"
  }
}
