# Production Environment Terragrunt Configuration

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Reference the infoblox module
terraform {
  source = "../../modules//infoblox"
}

# Dependencies on lower environments (for verification)
dependencies {
  paths = ["../dev", "../staging"]
}

# Environment-specific inputs
inputs = {
  environment = "prod"
  
  # Infoblox connection for production
  infoblox_server     = "infoblox-prod.company.com"
  infoblox_ssl_verify = true  # SSL required in production
  
  # Load configurations from YAML files
  config_files_path = "${get_terragrunt_dir()}/configs"
  
  # Environment-specific tags
  default_tags = {
    Environment   = "prod"
    ManagedBy     = "terragrunt"
    Project       = "infoblox-automation"
    CostCenter    = "engineering"
    Owner         = "platform-team"
    Backup        = "hourly"
    Monitoring    = "critical"
    Compliance    = "required"
  }
}

# Production-specific hooks
terraform {
  before_hook "production_warning" {
    commands = ["apply"]
    execute  = ["echo", "🚨 WARNING: Applying to PRODUCTION environment! 🚨"]
  }
  
  after_hook "production_notification" {
    commands     = ["apply"]
    execute      = ["echo", "✅ Production deployment completed successfully"]
    run_on_error = false
  }
}
