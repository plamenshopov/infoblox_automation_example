# Infoblox Terraform Automation Platform

A comprehensive infrastructure-as-code solution for managing Infoblox IPAM and DNS resources with automated Backstage integration, multi-environment support, and intelligent CI/CD pipelines.

## 🎯 Overview

This repository provides a complete automation platform for Infoblox infrastructure management, designed to support both automated provisioning through Backstage self-service and manual configuration management. The platform includes intelligent merge strategies, resource lifecycle management, and comprehensive testing capabilities.

## 🏗️ Architecture

### Repository Structure
```
infoblox/
├── 📁 live/                    # Terragrunt environments (DRY approach)
│   ├── terragrunt.hcl         # Root Terragrunt configuration
│   ├── dev/                   # Development environment
│   │   ├── terragrunt.hcl     # Environment-specific config
│   │   └── configs/           # YAML configuration files
│   │       ├── networks.yaml   # Network definitions
│   │       ├── dns-zones.yaml  # DNS zone configurations
│   │       ├── a-records.yaml  # A record definitions
│   │       ├── cname-records.yaml # CNAME record definitions
│   │       └── host-records.yaml  # Host record definitions
│   ├── staging/               # Staging environment
│   │   ├── terragrunt.hcl     # Environment-specific config
│   │   └── configs/           # YAML configuration files
│   └── prod/                  # Production environment
│       ├── terragrunt.hcl     # Environment-specific config
│       └── configs/           # YAML configuration files
├── 📁 modules/                # Reusable Terraform modules
│   ├── ipam/                  # IPAM resource management
│   │   ├── main.tf           # IPAM module implementation
│   │   ├── variables.tf      # Module input variables
│   │   └── outputs.tf        # Module outputs
│   ├── dns/                   # DNS resource management
│   │   ├── main.tf           # DNS module implementation
│   │   ├── variables.tf      # Module input variables
│   │   └── outputs.tf        # Module outputs
│   └── infoblox/              # Unified Infoblox module
│       ├── main.tf           # Combined IPAM/DNS management
│       ├── variables.tf      # Unified module variables
│       └── outputs.tf        # Unified module outputs
├── 📁 scripts/                # Automation and management scripts
│   ├── deploy.sh             # Standard Terraform deployment
│   ├── terragrunt-deploy.sh  # Terragrunt deployment wrapper
│   ├── validate-config.sh    # Configuration validation
│   ├── merge-backstage-config.py     # Backstage file merger
│   ├── manage-backstage-resources.py # Resource lifecycle management
│   └── cleanup-backstage-resources.sh # Automated cleanup
├── 📁 templates/              # Backstage self-service templates
│   └── backstage/
│       ├── dns-record-template.yaml  # DNS record creation template
│       ├── network-template.yaml     # Network creation template
│       └── content/                  # Template content files
├── 📁 .github/               # CI/CD pipeline definitions
│   ├── workflows/
│   │   ├── terraform-smart.yml      # Intelligent deployment pipeline
│   │   ├── process-backstage-records.yml # Backstage integration
│   │   └── terraform.yml           # Standard Terraform pipeline
│   └── actions/
│       └── merge-dns-config/        # Custom action for DNS merging
├── 📁 tests/                 # Comprehensive test suite
│   ├── test_functional.sh    # End-to-end functional tests
│   ├── test_conflict.sh      # Conflict resolution tests
│   ├── run_all_tests.sh      # Complete test suite runner
│   ├── fixtures/             # Test data and scenarios
│   └── README.md             # Test documentation
├── 📁 docs/                  # Comprehensive documentation
│   ├── getting-started.md           # Quick start guide
│   ├── configuration.md             # Configuration reference
│   ├── backstage.md                # Backstage integration guide
│   ├── terragrunt-comparison.md     # Terragrunt vs Terraform
│   ├── backstage-merge-strategy.md  # Merge strategy documentation
│   └── backstage-resource-management.md # Resource lifecycle docs
├── Makefile                  # Automation commands and targets
├── terragrunt.hcl           # Root Terragrunt configuration
├── test-setup.sh            # Environment setup validator
└── README.md                # This file
```

## 🚀 Features

### Core Capabilities
- **🏢 Multi-Environment Support**: Isolated dev, staging, and production environments
- **🧩 Modular Architecture**: Reusable Terraform modules for IPAM and DNS
- **🤖 Backstage Integration**: Self-service infrastructure provisioning
- **📝 YAML Configuration**: Human-readable configuration files
- **🔄 Intelligent Merging**: Automated Backstage configuration integration
- **🛡️ Resource Management**: Complete lifecycle management with cleanup
- **✅ Comprehensive Testing**: Automated validation and testing suite
- **🚀 CI/CD Pipelines**: Intelligent deployment automation

### Advanced Features
- **Unique Resource Tracking**: Backstage ID system for resource identification
- **Conflict Resolution**: Multiple strategies for handling configuration conflicts
- **Automatic Backups**: State and configuration backup before changes
- **Change Detection**: Smart pipeline execution based on file changes
- **Resource Cleanup**: Automated removal of Backstage-created resources
- **Validation**: Multi-layer configuration and infrastructure validation

## 📋 Supported Resources

### IPAM Resources
| Resource Type | Description | Configuration File |
|--------------|-------------|-------------------|
| **Networks** | Network and subnet definitions | `networks.yaml` |
| **Network Containers** | Hierarchical network organization | `networks.yaml` |
| **IP Allocations** | Static IP address assignments | `networks.yaml` |
| **Host Records** | Combined DNS + IP allocation | `host-records.yaml` |

### DNS Resources
| Resource Type | Description | Configuration File |
|--------------|-------------|-------------------|
| **DNS Zones** | Authoritative DNS zones | `dns-zones.yaml` |
| **A Records** | IPv4 address mappings | `a-records.yaml` |
| **CNAME Records** | Canonical name aliases | `cname-records.yaml` |
| **PTR Records** | Reverse DNS mappings | Generated automatically |
| **Host Records** | Combined forward/reverse DNS | `host-records.yaml` |

## 🛠️ Prerequisites

### Required Software
- **Terraform** >= 1.0
- **Terragrunt** >= 0.50 (primary deployment tool)
- **Python** 3.x with PyYAML (`pip install PyYAML`)
- **Git** for version control
- **Make** for automation commands

### Recommended Software
- **Azure CLI** (for Azure Storage state backend)
- **jq** (for JSON processing in scripts)

### Infrastructure Requirements
- **Infoblox NIOS** Grid Manager with API access
- **Azure Storage Account** for Terraform state (recommended)
- **GitHub** repository with Actions enabled
- **Backstage** platform (optional, for self-service)

## ⚡ Quick Start

### 1. Environment Setup

```bash
# Clone the repository
git clone <repository-url>
cd infoblox

# Test setup
./test-setup.sh

# Set environment variables
export ARM_STORAGE_ACCOUNT="your-storage-account"
export ARM_ACCESS_KEY="your-access-key"

# Validate dependencies
make check-terragrunt

# Quick development setup
make tg-dev-plan
```

### 2. Configuration

Create your first configuration in `live/dev/configs/`:

#### Networks (`networks.yaml`)
```yaml
# Development network configuration
dev_network_main:
  network_view: "default"
  network: "10.1.0.0/24"
  comment: "Main development network"
  ea_tags:
    Department: "Engineering"
    Environment: "dev"
    Owner: "platform-team"

dev_network_dmz:
  network_view: "default"
  network: "10.1.100.0/24"
  comment: "Development DMZ network"
  ea_tags:
    Department: "Engineering"
    Environment: "dev"
    Zone: "dmz"
```

#### DNS Zones (`dns-zones.yaml`)
```yaml
# DNS zone configuration
dev_internal_zone:
  zone: "dev.internal.company.com"
  view: "default"
  comment: "Development internal DNS zone"
  ea_tags:
    Environment: "dev"
    Type: "internal"
    Owner: "platform-team"
```

#### A Records (`a-records.yaml`)
```yaml
# A record configuration
dev_web_server:
  fqdn: "web01.dev.internal.company.com"
  ip_addr: "10.1.0.10"
  view: "default"
  ttl: 3600
  comment: "Development web server"
  ea_tags:
    Server_Type: "web"
    Environment: "dev"
    Service: "frontend"

dev_api_server:
  fqdn: "api01.dev.internal.company.com"
  ip_addr: "10.1.0.20"
  view: "default"
  ttl: 3600
  comment: "Development API server"
  ea_tags:
    Server_Type: "api"
    Environment: "dev"
    Service: "backend"
```

### 3. Deployment

Deploy your configuration:

```bash
# Plan changes
make tg-plan ENV=dev        # Review changes

# Apply changes
make tg-apply ENV=dev       # Apply changes

# Quick commands
make tg-dev-plan           # Quick plan for dev
make tg-dev-apply          # Quick apply for dev
```

## 🤖 Backstage Integration

### Self-Service DNS Records

The platform includes Backstage templates for self-service infrastructure provisioning:

1. **Navigate to Backstage Software Templates**
2. **Select "Create Infoblox DNS Record"**
3. **Fill in the form**:
   - Record name
   - IP address
   - Environment (dev/staging/prod)
   - TTL value
   - Additional metadata

4. **Submit the template** - creates a pull request with:
   - New YAML configuration file
   - Unique Backstage identifier
   - Proper resource tagging

### Automatic Integration

The CI/CD pipeline automatically processes Backstage-created records:

```yaml
# Generated by Backstage
# Environment: dev
# Backstage ID: my-app-dev-20250909120000

my_app_api:
  fqdn: "api.my-app.dev.internal.company.com"
  ip_addr: "10.1.0.100"
  view: "default"
  ttl: 3600
  comment: "My App API | Backstage ID: my-app-dev-20250909120000"
  ea_tags:
    Owner: "dev-team"
    CreatedBy: "backstage"
    CreatedAt: "2025-09-09T12:00:00Z"
    BackstageId: "my-app-dev-20250909120000"
    BackstageEntity: "my-app"
```

### Merge Process

The platform intelligently merges Backstage configurations:

```bash
# Manual merge (if needed)
python3 scripts/merge-backstage-config.py dev \
  --source-dir . \
  --strategy backstage-wins

# Available strategies:
# - backstage-wins: Backstage overrides existing
# - manual-protected: Preserves manual configurations
# - timestamp-wins: Newest configuration wins
# - fail-on-conflict: Fails safely on conflicts
```

## 🔄 CI/CD Pipelines

### Intelligent Deployment Pipeline

The `terraform-smart.yml` workflow provides:

#### Change Detection
- **File-based detection**: Only affected environments are processed
- **Dependency awareness**: Understands module and configuration relationships
- **Smart execution**: Skips unnecessary pipeline runs

#### Multi-Environment Support
```yaml
# Automatic deployment flow:
# 1. Development: Auto-deploy on feature branches
# 2. Staging: Auto-deploy on develop branch
# 3. Production: Manual approval required
```

#### Security Features
- **State backend**: Azure Storage with encryption
- **Credential management**: GitHub secrets integration
- **Approval gates**: Production deployments require manual approval
- **Audit logging**: Complete deployment history

### Backstage Integration Pipeline

The `process-backstage-records.yml` workflow:

1. **Detects Backstage-generated files**
2. **Validates configuration format**
3. **Merges with existing configurations**
4. **Creates deployment pull request**
5. **Provides rollback capabilities**

### Manual Workflow Triggers

```bash
# Trigger deployment manually
gh workflow run terraform-smart.yml \
  -f environment=prod \
  -f action=apply

# Process Backstage records manually
gh workflow run process-backstage-records.yml \
  -f environment=dev
```

## 📝 Commands Reference

### Makefile Commands

#### Terragrunt Commands (Primary)
```bash
# Environment management
make help                    # Show all available commands
make check-terragrunt        # Verify Terragrunt installation
make check-deps             # Verify required dependencies

# Deployment commands
make tg-plan ENV=dev        # Plan with Terragrunt
make tg-apply ENV=dev       # Apply with Terragrunt
make tg-destroy ENV=dev     # Destroy with Terragrunt
make tg-output ENV=dev      # Show Terragrunt outputs

# Multi-environment commands
make tg-plan-all            # Plan all environments
make tg-graph               # Generate dependency graph

# Quick Terragrunt commands
make tg-dev-plan            # Quick plan for dev
make tg-dev-apply           # Quick apply for dev
make tg-staging-plan        # Quick plan for staging
make tg-staging-apply       # Quick apply for staging
make tg-prod-plan           # Quick plan for production
make tg-prod-apply          # Quick apply for production

# Configuration management
make validate ENV=dev       # Validate configuration
make format                 # Format Terraform files
make lint                   # Lint Terraform files

# Utility commands
make tg-clean               # Clean Terragrunt cache
make clean                  # Clean up Terraform files
make docs                   # Generate documentation
make test                   # Run all tests and validations
```

#### Legacy Terraform Commands (Deprecated)
```bash
# These commands are deprecated but kept for reference
make init ENV=dev          # Initialize Terraform (deprecated)
make plan ENV=dev          # Create deployment plan (deprecated) 
make apply ENV=dev         # Apply changes (deprecated)
make destroy ENV=dev       # Destroy resources (deprecated)
```

### Script Commands

#### Deployment Scripts
```bash
# Terragrunt deployment (primary)
./scripts/terragrunt-deploy.sh dev plan    # Plan with Terragrunt
./scripts/terragrunt-deploy.sh dev apply   # Apply with Terragrunt
./scripts/terragrunt-deploy.sh all plan    # Plan all environments

# Configuration validation
./scripts/validate-config.sh dev           # Validate dev environment

# Standard Terraform deployment (deprecated)
./scripts/deploy.sh dev plan      # Plan deployment (deprecated)
./scripts/deploy.sh dev apply     # Apply changes (deprecated)
./scripts/deploy.sh dev destroy   # Destroy resources (deprecated)
```

#### Backstage Management Scripts
```bash
# Merge Backstage configurations
python3 scripts/merge-backstage-config.py dev \
  --source-dir . \
  --strategy backstage-wins

# Available strategies:
python3 scripts/merge-backstage-config.py dev \
  --strategy manual-protected     # Preserve manual configs
python3 scripts/merge-backstage-config.py dev \
  --strategy timestamp-wins       # Newest wins
python3 scripts/merge-backstage-config.py dev \
  --strategy fail-on-conflict     # Fail on conflicts

# Resource management
python3 scripts/manage-backstage-resources.py \
  --config-path live/dev/configs \
  list                           # List all Backstage resources

python3 scripts/manage-backstage-resources.py \
  --config-path live/dev/configs \
  find my-app                    # Find resources by entity

python3 scripts/manage-backstage-resources.py \
  --config-path live/dev/configs \
  cleanup my-app-dev-20250909120000  # Generate cleanup config

python3 scripts/manage-backstage-resources.py \
  validate "my-app-dev-20250909120000"  # Validate Backstage ID

# Cleanup resources
./scripts/cleanup-backstage-resources.sh my-app-dev-20250909120000
```

#### Testing Commands
```bash
# Run complete test suite
./tests/run_all_tests.sh

# Run individual tests
./tests/test_functional.sh      # Functional tests
./tests/test_conflict.sh        # Conflict resolution tests

# Test environment setup
./test-setup.sh                 # Validate environment setup
```

## 🧪 Testing

### Comprehensive Test Suite

The platform includes extensive testing capabilities:

#### Test Categories
- **Functional Tests**: End-to-end workflow validation
- **Conflict Resolution Tests**: Merge strategy validation
- **Integration Tests**: Full pipeline testing
- **Unit Tests**: Individual component testing

#### Running Tests
```bash
# Run complete test suite
./tests/run_all_tests.sh

# Expected output:
🎉 ALL TESTS PASSED! Your Backstage scripts are working perfectly.

🚀 Ready for production deployment:
   • Merge scripts handle file integration correctly
   • Resource management identifies and tracks Backstage resources
   • ID validation prevents invalid identifiers
   • Conflict detection and backup systems working

🏆 Final Score: 6/6 tests passed
```

#### Individual Test Execution
```bash
# Functional tests
./tests/test_functional.sh

# Conflict resolution tests
./tests/test_conflict.sh

# Validate specific components
python3 scripts/merge-backstage-config.py --help
python3 scripts/manage-backstage-resources.py --help
```

### Test Scenarios

The test suite validates:

✅ **Merge Functionality**
- Basic file merging
- Resource preservation
- Conflict detection
- Backup creation

✅ **Resource Management**
- Backstage resource identification
- Resource listing and filtering
- Cleanup configuration generation
- ID validation

✅ **Error Handling**
- Invalid configuration detection
- Missing file handling
- Malformed ID rejection

## 🔧 Configuration Reference

### Environment Variables

#### Terraform State Backend (Azure Storage)
```bash
export ARM_STORAGE_ACCOUNT="yourstorageaccount"
export ARM_ACCESS_KEY="your-access-key"
export ARM_CONTAINER_NAME="terraform-state"
export ARM_KEY="infoblox/dev/terraform.tfstate"
```

#### Infoblox Configuration
```bash
export INFOBLOX_SERVER="your-grid-manager.company.com"
export INFOBLOX_USERNAME="your-username"
export INFOBLOX_PASSWORD="your-password"
```

#### Optional Configuration
```bash
export TF_LOG="INFO"                    # Terraform logging level
export TG_LOG="INFO"                    # Terragrunt logging level
export PYTHONPATH="./scripts"           # Python script path
```

### Configuration Files

#### Terraform Variables (`terraform.tfvars`)
```hcl
# Infoblox connection settings
infoblox_server   = "your-grid-manager.company.com"
infoblox_username = "terraform-user"
infoblox_password = "secure-password"

# SSL verification (disable for self-signed certificates)
infoblox_ssl_verify = false

# Connection pool settings
infoblox_pool_connections = 10
infoblox_connect_timeout  = 60
infoblox_request_timeout  = 60

# Environment-specific settings
environment = "dev"
project     = "infoblox-automation"

# Tagging strategy
default_tags = {
  Environment    = "dev"
  Project        = "infoblox-automation"
  ManagedBy      = "terraform"
  BackupPolicy   = "daily"
  CostCenter     = "infrastructure"
}
```

### YAML Configuration Schema

#### A Records Configuration
```yaml
# a-records.yaml schema
record_name:
  fqdn: "server.example.com"       # Required: Fully qualified domain name
  ip_addr: "10.1.0.10"            # Required: IP address
  view: "default"                  # Required: DNS view name
  ttl: 3600                       # Optional: TTL in seconds (default: 3600)
  comment: "Description"           # Optional: Human-readable description
  ea_tags:                        # Optional: Extensible attributes
    Server_Type: "web"
    Environment: "dev"
    
# Backstage-generated records include additional fields:
record_name:
  fqdn: "app.example.com"
  ip_addr: "10.1.0.20"
  view: "default"
  ttl: 3600
  comment: "App Server | Backstage ID: app-dev-20250909120000"
  ea_tags:
    Server_Type: "app"
    Environment: "dev"
    BackstageId: "app-dev-20250909120000"    # Unique identifier
    BackstageEntity: "app"                   # Entity name
    CreatedBy: "backstage"                   # Creation source
    CreatedAt: "2025-09-09T12:00:00Z"       # Creation timestamp
```

## 🛡️ Security Best Practices

### Credential Management
- **Never commit credentials** to version control
- **Use environment variables** for sensitive data
- **Implement credential rotation** policies
- **Use Azure Key Vault** for production secrets

### Access Control
- **Principle of least privilege** for Infoblox API accounts
- **Environment isolation** with separate credentials
- **Audit logging** for all infrastructure changes
- **Multi-factor authentication** for production access

### State Security
- **Encrypted state storage** in Azure Storage
- **State file versioning** and backup
- **Access logging** for state file operations
- **State locking** to prevent concurrent modifications

### Pipeline Security
- **Branch protection** rules for main/production branches
- **Required reviews** for production deployments
- **Secrets scanning** in CI/CD pipelines
- **Dependency scanning** for security vulnerabilities

## 🔍 Troubleshooting

### Common Issues

#### Terraform Issues
```bash
# State lock issues
terraform force-unlock <lock-id>

# Provider authentication issues
export INFOBLOX_SERVER="your-server"
export INFOBLOX_USERNAME="your-username"
export INFOBLOX_PASSWORD="your-password"

# SSL certificate issues
# Add to terraform.tfvars:
infoblox_ssl_verify = false
```

#### Terragrunt Issues
```bash
# Cache issues
make tg-clean
terragrunt plan --terragrunt-working-dir live/dev

# Dependency issues
terragrunt graph-dependencies
terragrunt plan-all --terragrunt-non-interactive
```

#### Backstage Integration Issues
```bash
# Merge conflicts
python3 scripts/merge-backstage-config.py dev \
  --strategy manual-protected

# Resource tracking issues
python3 scripts/manage-backstage-resources.py \
  list --format json

# Cleanup issues
./scripts/cleanup-backstage-resources.sh --dry-run
```

### Debug Commands
```bash
# Enable Terraform debugging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Enable Terragrunt debugging
export TG_LOG=DEBUG
terragrunt plan --terragrunt-log-level debug

# Validate configurations
./scripts/validate-config.sh dev --verbose

### Support Resources
- **Documentation**: Check `docs/` directory for detailed guides
- **Test Suite**: Run `./tests/run_all_tests.sh` to verify functionality
- **Configuration Examples**: See `live/` directories for samples
- **GitHub Issues**: Report bugs and feature requests

## 📚 Documentation

### Available Documentation
- **[Getting Started Guide](docs/getting-started.md)** - Detailed setup instructions
- **[Configuration Reference](docs/configuration.md)** - Complete configuration options
- **[Backstage Integration](docs/backstage.md)** - Self-service setup guide
- **[Terragrunt Comparison](docs/terragrunt-comparison.md)** - Choose the right approach
- **[Merge Strategy Guide](docs/backstage-merge-strategy.md)** - Configuration merging
- **[Resource Management](docs/backstage-resource-management.md)** - Lifecycle management
- **[Test Documentation](tests/README.md)** - Testing guide and reference

### Quick Links
- **Environment Setup**: `docs/getting-started.md`
- **YAML Configuration**: `docs/configuration.md`
- **Backstage Templates**: `templates/backstage/`
- **Live Environments**: `live/dev/configs/`, `live/staging/configs/`, `live/prod/configs/`
- **Test Examples**: `tests/fixtures/`
- **Pipeline Configuration**: `.github/workflows/`

## 🤝 Contributing

### Development Workflow
1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/new-feature`)
3. **Make your changes**
4. **Test thoroughly** (`./tests/run_all_tests.sh`)
5. **Update documentation** as needed
6. **Submit a pull request**

### Code Standards
- **Terraform**: Follow HashiCorp best practices
- **Python**: Follow PEP 8 style guidelines
- **YAML**: Use consistent indentation (2 spaces)
- **Documentation**: Update README and docs for new features

### Testing Requirements
- **All tests must pass** before merging
- **Add tests** for new functionality
- **Validate** in development environment
- **Document** any breaking changes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🏆 Summary

This Infoblox Terraform Automation Platform provides:

✅ **Complete Infrastructure Management** with IPAM and DNS automation  
✅ **Multi-Environment Support** with dev/staging/production isolation  
✅ **Backstage Self-Service** with intelligent merge strategies  
✅ **Resource Lifecycle Management** with automated cleanup  
✅ **Comprehensive Testing** with 6/6 tests passing  
✅ **CI/CD Automation** with intelligent change detection  
✅ **Production-Ready** with security best practices  

**Ready for immediate deployment and production use!**
