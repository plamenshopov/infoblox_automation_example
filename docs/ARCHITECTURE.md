# Architecture Guide

This document provides a detailed overview of the Infoblox Terraform Automation Platform architecture, repository structure, and design decisions.

## 🏗️ Overview

The platform follows a **Terragrunt-first architecture** with clear separation of concerns, multi-environment support, and integrated self-service capabilities through Backstage.

## 📁 Repository Structure

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
│   │       ├── host-records.yaml  # Host record definitions
│   │       └── ip-reservations.yaml # IP address reservations
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
│   ├── terragrunt-deploy.sh  # Terragrunt deployment wrapper (primary)
│   ├── validate-config.sh    # Configuration validation
│   ├── backstage-cleanup.sh  # Targeted resource cleanup and state validation
│   ├── common-functions.sh   # Reusable utility functions library
│   ├── merge-backstage-config.py     # Backstage file merger
│   ├── manage-backstage-resources.py # Resource lifecycle management
│   └── deploy.sh             # Standard Terraform deployment (deprecated)
├── 📁 templates/              # Backstage self-service templates
│   └── backstage/
│       ├── dns-record-template.yaml     # DNS record creation template
│       ├── ip-reservation-template.yaml # IP reservation template
│       └── content/           # Template content generators
│           ├── ip-reservations.yaml    # IP reservation content template
│           └── ${{ values.recordType | lower }}-records.yaml # DNS content template
├── 📁 .github/               # CI/CD pipeline definitions
│   ├── workflows/
│   │   ├── terraform-smart.yml         # Intelligent deployment pipeline
│   │   ├── process-backstage-records.yml # Backstage integration
│   │   └── terraform.yml              # Standard Terraform pipeline
│   └── actions/
│       └── merge-dns-config/           # Custom action for DNS merging
├── 📁 tests/                 # Comprehensive test suite
│   ├── test-backstage-ip-reservations.sh # IP reservation template tests
│   ├── test_functional.sh             # End-to-end functional tests
│   ├── test_conflict.sh               # Conflict resolution tests
│   ├── run_all_tests.sh               # Complete test suite runner
│   ├── fixtures/                      # Test data and scenarios
│   └── README.md                      # Test documentation
├── 📁 docs/                  # Comprehensive documentation
│   ├── ARCHITECTURE.md              # This file
│   ├── COMMANDS.md                   # Commands reference
│   ├── CONFIGURATION.md              # Configuration reference
│   ├── BACKSTAGE.md                  # Backstage integration guide
│   ├── TESTING.md                    # Testing guide
│   ├── SECURITY.md                   # Security best practices
│   ├── TROUBLESHOOTING.md            # Troubleshooting guide
│   ├── CONTRIBUTING.md               # Contributing guidelines
│   ├── BACKSTAGE_IP_RESERVATION_TEMPLATE.md # IP reservation template guide
│   ├── IP_ADDRESS_MANAGEMENT.md      # IP address management strategies
│   ├── CLEANUP_GUIDE.md              # Resource cleanup procedures
│   ├── IMPLEMENTATION_SUMMARY.md     # Recent improvements and features
│   ├── terragrunt-comparison.md      # Terragrunt vs Terraform
│   ├── backstage-merge-strategy.md   # Merge strategy documentation
│   └── backstage-resource-management.md # Resource lifecycle docs
├── Makefile                  # Automation commands and targets
├── terragrunt.hcl           # Root Terragrunt configuration
├── test-setup.sh            # Basic environment setup validator
├── test-comprehensive.sh    # Comprehensive test suite with Makefile validation
└── README.md                # Main project documentation
```

## 🏛️ Architecture Principles

### 1. **DRY (Don't Repeat Yourself)**
- **Terragrunt configuration**: Shared configuration with environment-specific overrides
- **Reusable modules**: Common Terraform modules across environments
- **Shared scripts**: Common functionality in `scripts/common-functions.sh`

### 2. **Environment Separation**
- **Physical separation**: Each environment in its own directory
- **Independent state**: Separate Terraform state files per environment
- **Configuration isolation**: Environment-specific YAML configurations

### 3. **Configuration as Code**
- **YAML-driven**: Human-readable configuration files
- **Version controlled**: All configurations tracked in Git
- **Validated**: Multi-layer validation before deployment

### 4. **Self-Service Integration**
- **Backstage templates**: Self-service infrastructure provisioning
- **Automated workflows**: GitHub Actions for processing requests
- **Unique identification**: Backstage ID system for resource tracking

## 🔧 Component Relationships

### Configuration Flow
```
YAML Configs → Terragrunt → Terraform → Infoblox NIOS
     ↑              ↑           ↑           ↑
Backstage → GitHub Actions → Validation → Deployment
```

### Data Flow
1. **Configuration**: YAML files define desired state
2. **Validation**: Multiple validation layers ensure correctness
3. **Planning**: Terragrunt generates execution plan
4. **Deployment**: Changes applied to Infoblox NIOS
5. **Verification**: Post-deployment validation and testing

## 🗂️ Directory Deep Dive

### `/live/` - Environment Configurations

**Purpose**: Environment-specific configurations using Terragrunt DRY approach

**Structure**:
- `terragrunt.hcl`: Root configuration with shared settings
- `{env}/terragrunt.hcl`: Environment-specific overrides
- `{env}/configs/`: YAML configuration files per environment

**Key Features**:
- Environment isolation
- Shared configuration patterns
- Independent state management
- Environment-specific variable overrides

### `/modules/` - Terraform Modules

**Purpose**: Reusable Terraform modules for different resource types

**Modules**:
- **`ipam/`**: IP address management (networks, subnets, allocations)
- **`dns/`**: DNS management (zones, records, views)
- **`infoblox/`**: Unified module combining IPAM and DNS

**Design Pattern**:
- Standard Terraform module structure
- Input variables for customization
- Outputs for resource references
- Documentation and examples

### `/scripts/` - Automation Scripts

**Purpose**: Deployment, validation, and management automation

**Key Scripts**:
- **`terragrunt-deploy.sh`**: Primary deployment wrapper
- **`backstage-cleanup.sh`**: Resource lifecycle management
- **`common-functions.sh`**: Shared utility functions
- **`validate-config.sh`**: Configuration validation

**Features**:
- Error handling and logging
- Environment variable support
- Comprehensive validation
- Integration with CI/CD

### `/templates/` - Backstage Self-Service

**Purpose**: Self-service templates for infrastructure provisioning

**Templates**:
- **DNS Records**: A, CNAME, HOST record creation
- **IP Reservations**: 8 different reservation types
- **Content Generators**: Dynamic YAML generation

**Integration**:
- Backstage Software Templates
- GitHub Actions processing
- Unique identifier generation
- Pull request automation

### `/tests/` - Testing Framework

**Purpose**: Comprehensive testing and validation

**Test Types**:
- **Unit tests**: Module and script validation
- **Integration tests**: End-to-end workflow testing
- **Template tests**: Backstage template validation
- **Functional tests**: Real environment testing

**Coverage**:
- 45+ automated tests
- Multiple validation layers
- Performance testing
- Security validation

## 🔄 Deployment Workflows

### 1. **Manual Deployment**
```bash
make tg-plan ENV=dev     # Plan changes
make tg-apply ENV=dev    # Apply changes
make tg-output ENV=dev   # View outputs
```

### 2. **Backstage Self-Service**
```
User → Backstage Template → GitHub PR → Actions → Terragrunt → Infoblox
```

### 3. **CI/CD Pipeline**
```
Git Push → GitHub Actions → Validation → Plan → Manual Approval → Apply
```

## 🛠️ Technology Stack

### Core Tools
- **Terragrunt**: >= 0.50 (primary deployment tool)
- **Terraform**: >= 1.5 (infrastructure as code)
- **Python**: 3.x (automation scripts)
- **YAML**: Configuration format

### Integration Tools
- **Backstage**: Self-service platform
- **GitHub Actions**: CI/CD automation
- **Make**: Build automation
- **Bash**: Scripting and automation

### Infoblox Integration
- **NIOS API**: REST API for resource management
- **Provider**: Terraform Infoblox provider
- **Authentication**: API credentials and certificates

## 📊 State Management

### Terragrunt State
- **Backend**: Configured per environment
- **Locking**: Prevents concurrent modifications
- **Encryption**: State encryption at rest
- **Backup**: Automated state backup strategies

### Configuration State
- **Git**: Version control for all configurations
- **Branching**: Feature branches for changes
- **Reviews**: Pull request validation
- **History**: Complete audit trail

## 🔐 Security Architecture

### Access Control
- **Role-based access**: Different permissions per environment
- **API credentials**: Secure credential management
- **Network security**: VPN/private network access
- **Audit logging**: Complete action logging

### Data Protection
- **Encryption**: In-transit and at-rest encryption
- **Secrets management**: Secure credential storage
- **Backup**: Regular backup procedures
- **Recovery**: Disaster recovery planning

## 📈 Scalability Considerations

### Horizontal Scaling
- **Multiple environments**: Easy environment addition
- **Module reuse**: Shared modules across teams
- **Template expansion**: Additional Backstage templates
- **Provider support**: Multiple Infoblox appliances

### Performance Optimization
- **Parallel execution**: Terragrunt parallelism
- **Caching**: Build and dependency caching
- **Resource optimization**: Efficient resource planning
- **Monitoring**: Performance monitoring and alerting

## 🔧 Extensibility

### Adding New Resource Types
1. Create Terraform module in `/modules/`
2. Add YAML configuration schema
3. Update validation scripts
4. Create Backstage template (optional)
5. Add tests and documentation

### Environment Addition
1. Create environment directory in `/live/`
2. Copy and customize `terragrunt.hcl`
3. Create configuration files in `configs/`
4. Update CI/CD pipeline configuration
5. Test and validate new environment

### Integration Extension
1. Add new scripts in `/scripts/`
2. Update common functions library
3. Create integration documentation
4. Add comprehensive tests
5. Update CI/CD workflows

This architecture provides a solid foundation for enterprise-scale Infoblox automation while maintaining flexibility for future enhancements and integrations.
