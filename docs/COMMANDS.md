# Commands Reference

Complete reference for all commands, scripts, and utilities in the Infoblox Terraform Automation Platform.

## 📋 Quick Command Reference

### Most Common Commands
```bash
# Development workflow
make tg-dev-plan                    # Plan dev environment
make tg-dev-apply                   # Apply dev changes
make test                          # Run tests
make validate ENV=dev              # Validate configuration

# Production workflow  
make tg-plan ENV=prod              # Plan production changes
make tg-apply ENV=prod             # Apply production changes (with confirmation)

# Cleanup and maintenance
make tg-clean                      # Clean Terragrunt cache
make backstage-cleanup-entity ENV=dev ENTITY=my-app  # Remove entity resources
```

## 🔧 Makefile Commands

### Environment Management
```bash
make help                          # Show all available commands
make check-terragrunt              # Verify Terragrunt installation
make check-deps                    # Verify required dependencies
make validate ENV={env}            # Validate environment configuration
```

### Terragrunt Commands (Primary)

#### Planning and Deployment
```bash
# Single environment operations
make tg-plan ENV={env}             # Plan changes for environment
make tg-apply ENV={env}            # Apply changes for environment  
make tg-destroy ENV={env}          # Destroy all resources (DANGEROUS)
make tg-output ENV={env}           # Show Terragrunt outputs

# Multi-environment operations
make tg-plan-all                   # Plan all environments
make tg-graph                      # Generate dependency graph
```

#### Quick Environment Commands
```bash
# Development
make tg-dev-plan                   # Quick plan for dev environment
make tg-dev-apply                  # Quick apply for dev environment

# Staging
make tg-staging-plan               # Quick plan for staging environment
make tg-staging-apply              # Quick apply for staging environment

# Production (with extra confirmation)
make tg-prod-plan                  # Quick plan for production
make tg-prod-apply                 # Quick apply for production
```

### Configuration Management
```bash
make format                        # Format Terraform files
make lint                          # Lint Terraform files  
make validate ENV={env}            # Validate configuration files
make validate-state ENV={env}      # Validate state consistency
```

### Testing Commands
```bash
make test                          # Run basic setup tests
make test-comprehensive            # Run comprehensive test suite
make test-backstage-ip             # Test IP reservation Backstage template
make test-makefile                 # Test Makefile targets (safe operations)
```

### Cleanup Commands
```bash
make tg-clean                      # Clean Terragrunt cache
make clean                         # Clean up Terraform files
```

### Backstage Resource Management
```bash
# Resource listing and discovery
make backstage-list ENV={env}      # List all Backstage resources
make backstage-preview-entity ENV={env} ENTITY={name}  # Preview entity cleanup
make backstage-preview-id ENV={env} ID={id}           # Preview ID cleanup

# Resource removal
make backstage-cleanup-entity ENV={env} ENTITY={name} # Remove entity resources
make backstage-cleanup-id ENV={env} ID={id}          # Remove specific resource
```

### Documentation
```bash
make docs                          # Generate documentation
```

## 🚀 Direct Script Usage

### Terragrunt Deployment (Primary)
```bash
# Basic operations
./scripts/terragrunt-deploy.sh {env} plan     # Plan environment changes
./scripts/terragrunt-deploy.sh {env} apply    # Apply environment changes  
./scripts/terragrunt-deploy.sh {env} destroy  # Destroy environment resources
./scripts/terragrunt-deploy.sh {env} output   # Show environment outputs

# Multi-environment operations
./scripts/terragrunt-deploy.sh all plan       # Plan all environments
./scripts/terragrunt-deploy.sh all graph      # Generate dependency graph

# Examples
./scripts/terragrunt-deploy.sh dev plan       # Plan dev environment
./scripts/terragrunt-deploy.sh staging apply  # Apply staging changes
./scripts/terragrunt-deploy.sh prod destroy   # Destroy prod (with confirmation)
```

### Configuration Validation
```bash
# Validate specific environment
./scripts/validate-config.sh dev              # Validate dev environment
./scripts/validate-config.sh staging          # Validate staging environment
./scripts/validate-config.sh prod             # Validate production environment

# Validation includes:
# - YAML syntax validation
# - Terragrunt configuration validation  
# - Terraform file syntax validation
# - Remote state accessibility
# - Cross-environment consistency
```

### Backstage Configuration Management
```bash
# Merge Backstage configurations with different strategies
python3 scripts/merge-backstage-config.py {env} --strategy {strategy}

# Available strategies:
python3 scripts/merge-backstage-config.py dev --strategy backstage-wins      # Backstage takes precedence
python3 scripts/merge-backstage-config.py dev --strategy manual-protected    # Preserve manual configs  
python3 scripts/merge-backstage-config.py dev --strategy timestamp-wins      # Newest timestamp wins
python3 scripts/merge-backstage-config.py dev --strategy fail-on-conflict    # Fail on conflicts

# Additional options:
python3 scripts/merge-backstage-config.py dev \
  --source-dir . \
  --strategy backstage-wins \
  --dry-run                                   # Preview changes without applying
```

### Resource Lifecycle Management
```bash
# List and find resources
python3 scripts/manage-backstage-resources.py \
  --config-path live/{env}/configs \
  list                                        # List all Backstage resources

python3 scripts/manage-backstage-resources.py \
  --config-path live/{env}/configs \
  find {entity-name}                          # Find resources by entity

# Resource cleanup
python3 scripts/manage-backstage-resources.py \
  --config-path live/{env}/configs \
  cleanup {backstage-id}                      # Generate cleanup configuration

# Validation
python3 scripts/manage-backstage-resources.py \
  validate "{backstage-id}"                   # Validate Backstage ID format

# Examples:
python3 scripts/manage-backstage-resources.py \
  --config-path live/dev/configs \
  find my-web-app                             # Find all my-web-app resources

python3 scripts/manage-backstage-resources.py \
  --config-path live/dev/configs \
  cleanup my-app-dev-20250910140000           # Generate cleanup for specific ID
```

### Resource Cleanup Operations
```bash
# List Backstage resources
./scripts/backstage-cleanup.sh {env} list-backstage       # List all Backstage resources
./scripts/backstage-cleanup.sh {env} list-manual          # List manual resources

# Preview cleanup operations (safe)
./scripts/backstage-cleanup.sh {env} preview-entity {entity}  # Preview entity removal
./scripts/backstage-cleanup.sh {env} preview-id {id}          # Preview ID removal

# Execute cleanup operations
./scripts/backstage-cleanup.sh {env} cleanup-entity {entity}  # Remove entity resources
./scripts/backstage-cleanup.sh {env} cleanup-id {id}          # Remove specific resource

# State validation
./scripts/backstage-cleanup.sh {env} validate-state           # Validate state consistency

# Examples:
./scripts/backstage-cleanup.sh dev preview-entity my-app      # Preview cleanup for my-app
./scripts/backstage-cleanup.sh dev cleanup-id my-app-dev-20250910140000  # Remove specific resource
./scripts/backstage-cleanup.sh prod validate-state            # Validate production state
```

## 🧪 Testing Commands

### Test Execution
```bash
# Basic testing
./test-setup.sh                               # Basic environment validation
./test-comprehensive.sh                       # Full test suite

# Specific test categories
./tests/test-backstage-ip-reservations.sh     # IP reservation template tests

# Test through Makefile
make test                                     # Basic tests
make test-comprehensive                       # Comprehensive test suite  
make test-backstage-ip                        # IP reservation template tests
make test-makefile                           # Makefile functionality tests
```

### Test Configuration
```bash
# Test specific environments
TEST_ENV=dev ./test-comprehensive.sh          # Test dev environment
TEST_ENV=staging ./test-comprehensive.sh      # Test staging environment

# Test with specific parameters
TEST_ENTITY=my-test-app ./test-comprehensive.sh  # Test with specific entity
```

## 🔍 Common Function Library

### Loading Common Functions
```bash
# In any script, load the common functions library
source scripts/common-functions.sh

# Now you have access to all common functions
```

### Logging Functions
```bash
log_info "Information message"                # Blue info message
log_success "Success message"                 # Green success message  
log_warning "Warning message"                 # Yellow warning message
log_error "Error message"                     # Red error message
```

### Validation Functions
```bash
# Environment validation
validate_environment_exists "dev"             # Check if environment exists
validate_required_tools "python3" "make"      # Check required tools

# Tool availability
check_tool_available "terragrunt"             # Check if tool is available
check_terragrunt_version                      # Validate Terragrunt version

# Configuration validation
validate_terragrunt_state "dev"               # Validate Terragrunt state
validate_terraform_syntax "dev"               # Validate Terraform syntax
validate_yaml_files "live/dev/configs"        # Validate YAML files
validate_environment_consistency "dev"        # Cross-tool validation
```

### File Operations
```bash
# Backup operations
create_backup "dev"                           # Create environment backup
safe_file_operation "backup" "config.yaml"   # Safe file operations with backup

# Makefile operations
run_makefile_target "help"                    # Run Makefile target safely
test_makefile_target "validate ENV=dev"       # Test Makefile target
```

## 📊 State Management Commands

### State Validation
```bash
# Through Makefile
make validate-state ENV=dev                   # Validate environment state

# Direct script usage
./scripts/backstage-cleanup.sh dev validate-state  # Validate state consistency

# Using common functions
source scripts/common-functions.sh
validate_environment_consistency dev          # Comprehensive validation
```

### State Operations
```bash
# Terragrunt state operations
terragrunt state list                         # List resources in state
terragrunt state show {resource}              # Show resource details
terragrunt state pull                         # Download remote state

# Terraform state operations (within environment directory)
cd live/dev
terraform state list                          # List state resources
terraform state show {resource}               # Show resource details
```

## 🔄 Environment-Specific Examples

### Development Environment
```bash
# Complete development workflow
make tg-dev-plan                              # Plan changes
make test                                     # Run tests
make tg-dev-apply                             # Apply changes
make tg-output ENV=dev                        # View results
```

### Staging Environment  
```bash
# Staging deployment workflow
make validate ENV=staging                     # Validate configuration
make tg-plan ENV=staging                      # Plan changes
make test-comprehensive                       # Run full tests
make tg-apply ENV=staging                     # Apply changes
```

### Production Environment
```bash
# Production deployment (extra confirmation required)
make validate ENV=prod                        # Validate configuration
make tg-plan ENV=prod                         # Plan changes
make test-comprehensive                       # Run comprehensive tests
# Manual review of plan output
make tg-apply ENV=prod                        # Apply with confirmation prompts
make tg-output ENV=prod                       # Verify deployment
```

## 🚨 Emergency Commands

### Rollback Operations
```bash
# If you need to rollback changes
git revert {commit-hash}                      # Revert configuration changes
make tg-plan ENV={env}                        # Plan rollback
make tg-apply ENV={env}                       # Apply rollback
```

### Emergency Cleanup
```bash
# Clean all caches and temporary files
make tg-clean                                 # Clean Terragrunt cache
make clean                                    # Clean Terraform files
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
```

### State Recovery
```bash
# If state becomes inconsistent
terragrunt refresh                            # Refresh state from real infrastructure
terragrunt import {resource} {id}             # Import existing resource
terragrunt state rm {resource}                # Remove resource from state
```

## 💡 Tips and Best Practices

### Command Patterns
```bash
# Always validate before applying
make validate ENV={env} && make tg-plan ENV={env} && make tg-apply ENV={env}

# Test changes in development first
make tg-dev-plan && make test && make tg-dev-apply

# Use preview commands for safety
make backstage-preview-entity ENV=prod ENTITY=critical-app

# Clean up regularly
make tg-clean  # Weekly cache cleanup
```

### Error Handling
```bash
# Check command exit codes
if make tg-plan ENV=dev; then
    echo "Plan successful"
    make tg-apply ENV=dev
else
    echo "Plan failed, investigating..."
    make validate ENV=dev
fi
```

### Debugging Commands
```bash
# Enable verbose output
export TG_LOG=debug                           # Terragrunt debug logging
export TF_LOG=debug                           # Terraform debug logging

# Dry run operations
python3 scripts/merge-backstage-config.py dev --dry-run  # Preview merge
make backstage-preview-entity ENV=dev ENTITY=my-app      # Preview cleanup
```

This comprehensive command reference covers all available operations in the platform. For specific use cases or troubleshooting, refer to the [Troubleshooting Guide](TROUBLESHOOTING.md).
