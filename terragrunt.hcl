# Terragrunt Configuration for Infoblox Automation

# This is the root terragrunt.hcl file that defines common configurations
# for all environments and modules.

# Generate common provider configurations
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    infoblox = {
      source  = "infobloxopen/infoblox"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "infoblox" {
  username = var.infoblox_username
  password = var.infoblox_password
  server   = var.infoblox_server
  sslmode  = var.infoblox_ssl_verify
  
  connect_timeout  = 60
  pool_connections = 10
}

provider "aws" {
  region = var.aws_region
}
EOF
}

# Generate common variables
generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
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

variable "aws_region" {
  description = "AWS region for state storage"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "infoblox-automation"
}
EOF
}

# Remote state configuration
remote_state {
  backend = "s3"
  config = {
    bucket         = get_env("TG_BUCKET_NAME", "your-terraform-state-bucket")
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = get_env("AWS_REGION", "us-east-1")
    encrypt        = true
    dynamodb_table = get_env("TG_DYNAMODB_TABLE", "terraform-lock")
    
    s3_bucket_tags = {
      Environment = "shared"
      Purpose     = "terraform-state"
      Project     = "infoblox-automation"
    }
    
    dynamodb_table_tags = {
      Environment = "shared"
      Purpose     = "terraform-lock"
      Project     = "infoblox-automation"
    }
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Input variables that should be passed to all modules
inputs = {
  project_name = "infoblox-automation"
}
