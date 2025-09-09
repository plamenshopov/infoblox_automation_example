# Contributing to Infoblox Terraform Automation Platform

Welcome to the Infoblox Terraform Automation Platform! We appreciate your interest in contributing to this project. This guide will help you understand our development workflow, coding standards, and testing requirements.

## 🤝 How to Contribute

### Getting Started

1. **Fork the Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/your-username/infoblox-terraform-automation.git
   cd infoblox-terraform-automation
   
   # Add upstream remote
   git remote add upstream https://github.com/original-org/infoblox-terraform-automation.git
   ```

2. **Set Up Development Environment**
   ```bash
   # Install required tools
   make check-deps
   
   # Configure development environment
   cp live/dev/configs/example.yaml live/dev/configs/your-feature.yaml
   
   # Run initial tests
   make test
   ```

3. **Create Feature Branch**
   ```bash
   # Update main branch
   git checkout main
   git pull upstream main
   
   # Create feature branch
   git checkout -b feature/your-new-feature
   
   # Or for bug fixes
   git checkout -b fix/issue-description
   ```

## 🔧 Development Workflow

### Standard Development Process

1. **Plan Your Changes**
   - Review existing issues and discussions
   - Create or comment on relevant GitHub issues
   - Discuss major changes with maintainers first

2. **Make Your Changes**
   ```bash
   # Make changes to relevant files
   # Add new tests for new functionality
   # Update documentation as needed
   ```

3. **Test Your Changes**
   ```bash
   # Run comprehensive test suite
   make test-comprehensive
   
   # Run specific test categories
   make test-makefile
   make test-backstage-ip
   make test-yaml-validation
   
   # Test in development environment
   make tg-plan ENV=dev
   make validate ENV=dev
   ```

4. **Commit and Push**
   ```bash
   # Stage your changes
   git add .
   
   # Commit with descriptive message
   git commit -m "feat: add new IP reservation feature
   
   - Add automated IP reservation workflow
   - Implement validation for IP ranges
   - Update documentation and tests
   
   Closes #123"
   
   # Push to your fork
   git push origin feature/your-new-feature
   ```

5. **Submit Pull Request**
   - Create pull request on GitHub
   - Fill out the pull request template
   - Link related issues
   - Request review from maintainers

### Branch Naming Conventions

Use descriptive branch names with prefixes:

- `feature/` - New features or enhancements
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring without functionality changes
- `test/` - Test improvements or additions
- `chore/` - Maintenance tasks

Examples:
- `feature/ip-reservation-backstage-template`
- `fix/terragrunt-cache-corruption`
- `docs/troubleshooting-guide-update`
- `refactor/common-functions-library`

## 📏 Code Standards

### Terraform Standards

Follow HashiCorp best practices and our project conventions:

```hcl
# Use descriptive resource names
resource "infoblox_a_record" "web_server" {
  fqdn     = "web.example.com"
  ip_addr  = "10.1.1.100"
  comment  = "Web server A record"
  ttl      = 3600
  
  # Use tags for organization
  ext_attrs = jsonencode({
    Environment = var.environment
    Project     = "web-services"
    Owner       = "platform-team"
  })
}

# Use variables for reusability
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition = contains([
      "dev",
      "staging", 
      "prod"
    ], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Use locals for computed values
locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "terraform"
    CreatedBy     = "infoblox-automation"
  }
}
```

### Python Standards

Follow PEP 8 style guidelines:

```python
#!/usr/bin/env python3
"""
Script for managing Backstage resources.

This module provides functionality for CRUD operations on Backstage-managed
resources with proper error handling and validation.
"""

import argparse
import logging
import sys
from pathlib import Path
from typing import Dict, List, Optional, Union

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class BackstageResourceManager:
    """Manage Backstage resources with validation and error handling."""
    
    def __init__(self, config_path: Path) -> None:
        """
        Initialize the resource manager.
        
        Args:
            config_path: Path to configuration directory
            
        Raises:
            ValueError: If config_path is invalid
        """
        if not config_path.exists():
            raise ValueError(f"Configuration path does not exist: {config_path}")
        
        self.config_path = config_path
        self.resources: Dict[str, Dict] = {}
    
    def load_resources(self) -> Dict[str, Dict]:
        """
        Load all resources from configuration files.
        
        Returns:
            Dictionary of loaded resources
            
        Raises:
            FileNotFoundError: If configuration files are missing
            yaml.YAMLError: If YAML parsing fails
        """
        try:
            # Implementation here
            pass
        except Exception as e:
            logger.error(f"Failed to load resources: {e}")
            raise


def main() -> int:
    """Main entry point."""
    try:
        # Implementation here
        return 0
    except Exception as e:
        logger.error(f"Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
```

### Shell Script Standards

Use consistent shell scripting practices:

```bash
#!/bin/bash
# Script for automated testing of Backstage IP reservations
#
# Usage: ./test-backstage-ip-reservations.sh [environment]
# Example: ./test-backstage-ip-reservations.sh dev

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Global configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly DEFAULT_ENV="dev"

# Source common functions
# shellcheck source=scripts/common-functions.sh
source "${PROJECT_ROOT}/scripts/common-functions.sh"

# Function definitions
validate_environment() {
    local env="${1:-}"
    
    if [[ -z "${env}" ]]; then
        log_error "Environment parameter is required"
        return 1
    fi
    
    if [[ ! -d "${PROJECT_ROOT}/live/${env}" ]]; then
        log_error "Environment directory not found: ${env}"
        return 1
    fi
    
    log_info "Environment validated: ${env}"
    return 0
}

main() {
    local environment="${1:-${DEFAULT_ENV}}"
    
    log_info "Starting Backstage IP reservation tests"
    
    # Validate inputs
    validate_environment "${environment}" || exit 1
    
    # Test implementation
    # ...
    
    log_info "All tests completed successfully"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### YAML Standards

Use consistent YAML formatting:

```yaml
# Use 2-space indentation
# Use descriptive keys
# Include comments for complex configurations

networks:
  # Development environment networks
  development:
    primary:
      network: "10.100.0.0/16"
      description: "Development primary network"
      gateway: "10.100.0.1"
      dns_servers:
        - "10.100.0.10"
        - "10.100.0.11"
      
    management:
      network: "10.100.100.0/24"
      description: "Development management network"
      gateway: "10.100.100.1"

ip_reservations:
  # Static IP reservations for development
  - name: "web-server-dev"
    ip_address: "10.100.1.100"
    description: "Development web server"
    environment: "dev"
    project: "web-services"
    owner: "platform-team"
    
  - name: "db-server-dev"
    ip_address: "10.100.1.101"
    description: "Development database server"
    environment: "dev"
    project: "web-services"
    owner: "platform-team"
```

## 🧪 Testing Requirements

### Test Categories

Our testing framework includes several categories:

1. **Unit Tests** - Individual function testing
2. **Integration Tests** - Component interaction testing  
3. **End-to-End Tests** - Complete workflow testing
4. **Configuration Tests** - YAML and configuration validation
5. **Template Tests** - Backstage template validation

### Required Testing

Before submitting a pull request:

```bash
# Run all tests
make test-comprehensive

# Specific test categories
make test-makefile          # Makefile functionality
make test-backstage-ip      # Backstage IP reservations
make test-yaml-validation   # YAML syntax validation
make test-template          # Template processing

# Manual testing in development
make tg-plan ENV=dev
make validate ENV=dev
```

### Writing New Tests

When adding new functionality, include appropriate tests:

```bash
# Test script template
#!/bin/bash
# Test script for new feature

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common test functions
source "${PROJECT_ROOT}/tests/test-helpers.sh"

test_new_feature() {
    log_info "Testing new feature..."
    
    # Test setup
    local test_config="${PROJECT_ROOT}/tests/fixtures/test-config.yaml"
    
    # Execute test
    if your_new_command --config "${test_config}"; then
        log_info "✅ New feature test passed"
        return 0
    else
        log_error "❌ New feature test failed"
        return 1
    fi
}

main() {
    log_info "Starting new feature tests"
    
    test_new_feature || exit 1
    
    log_info "All new feature tests passed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Test Data and Fixtures

Use test fixtures for consistent testing:

```yaml
# tests/fixtures/test-ip-reservations.yaml
test_reservations:
  - name: "test-server-1"
    ip_address: "192.168.100.10"
    description: "Test server for unit tests"
    environment: "test"
    project: "testing"
    
  - name: "test-server-2"
    ip_address: "192.168.100.11"
    description: "Test server for integration tests"
    environment: "test"
    project: "testing"
```

## 📖 Documentation Requirements

### Documentation Updates

Always update documentation when making changes:

1. **README.md** - Update main documentation
2. **docs/** - Update relevant specialized documentation
3. **Code Comments** - Add/update inline documentation
4. **Configuration Examples** - Update example configurations
5. **Test Documentation** - Document new test procedures

### Documentation Standards

```markdown
# Use clear hierarchical headings

## Feature Description
Brief description of what the feature does.

### Usage Examples
```bash
# Provide clear, working examples
make feature-command ENV=dev
```

### Configuration
```yaml
# Show complete configuration examples
feature_config:
  enabled: true
  parameters:
    - name: "example"
      value: "test"
```

### Troubleshooting
Common issues and solutions for the feature.
```

## 🔍 Code Review Process

### Pull Request Guidelines

1. **Use PR Template** - Fill out all sections
2. **Link Issues** - Reference related GitHub issues
3. **Describe Changes** - Explain what and why
4. **Include Screenshots** - For UI changes
5. **Test Results** - Include test output

### Review Criteria

Reviewers will check for:

- **Functionality** - Does it work as intended?
- **Testing** - Are there adequate tests?
- **Documentation** - Is documentation updated?
- **Code Quality** - Follows coding standards?
- **Security** - No security vulnerabilities?
- **Performance** - No performance regressions?

### Addressing Review Comments

```bash
# Make requested changes
git add .
git commit -m "address review comments: improve error handling"

# Push updates
git push origin feature/your-new-feature

# Respond to comments on GitHub
```

## 🚀 Release Process

### Versioning Strategy

We use semantic versioning (SemVer):

- **MAJOR** - Breaking changes
- **MINOR** - New features (backward compatible)
- **PATCH** - Bug fixes (backward compatible)

### Release Checklist

For maintainers preparing releases:

1. **Update Version Numbers**
2. **Update CHANGELOG.md**
3. **Run Full Test Suite**
4. **Update Documentation**
5. **Create Release Notes**
6. **Tag Release**
7. **Deploy to Environments**

## 🆘 Getting Help

### Resources

- **Documentation**: Check docs/ directory first
- **Issues**: Search existing GitHub issues
- **Discussions**: Join GitHub discussions
- **Tests**: Run test suite for examples

### Asking Questions

When asking for help:

1. **Search First** - Check existing issues/docs
2. **Provide Context** - Include environment details
3. **Show Code** - Include relevant configuration
4. **Include Logs** - Add error messages/outputs
5. **Describe Expected** - What should happen?

### Example Question Format

```markdown
## Issue Description
Brief description of the problem.

## Environment
- OS: Ubuntu 20.04
- Terraform: 1.5.7
- Terragrunt: 0.50.17
- Environment: dev

## Configuration
```yaml
# Include relevant config
```

## Steps to Reproduce
1. Run command X
2. See error Y

## Expected Behavior
What should happen instead?

## Actual Behavior
What actually happened?

## Logs/Output
```
Include error messages or relevant output
```
```

## 🏆 Recognition

We appreciate all contributions! Contributors will be:

- **Listed** in CONTRIBUTORS.md
- **Credited** in release notes
- **Mentioned** in relevant documentation
- **Thanked** in community discussions

## 📄 Legal

By contributing to this project, you agree that your contributions will be licensed under the same license as the project (MIT License).

Thank you for contributing to the Infoblox Terraform Automation Platform! 🎉
