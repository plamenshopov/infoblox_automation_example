# Troubleshooting Guide

Comprehensive troubleshooting guide for common issues and problems in the Infoblox Terraform Automation Platform.

## 🔍 Overview

This guide covers common issues, diagnostic procedures, and solutions for the Infoblox automation platform. Issues are organized by category with detailed resolution steps.

## 🚨 Quick Diagnostic Commands

### System Health Check
```bash
# Run comprehensive diagnostics
make test-comprehensive

# Quick system validation
make test

# Check tool availability
make check-deps

# Validate specific environment
make validate ENV=dev
```

### Environment Status
```bash
# Check current state
make tg-output ENV=dev

# Validate state consistency
make validate-state ENV=dev

# Clean and refresh
make tg-clean
make tg-plan ENV=dev
```

## 🛠️ Terragrunt Issues

### Cache and Dependency Issues

#### Problem: Terragrunt cache corruption
```
Error: Failed to load module from cache
Error: Could not determine underlying exit code
```

**Solution:**
```bash
# Clean Terragrunt cache
make tg-clean

# Manual cache cleanup
find . -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true

# Reinitialize
make tg-plan ENV=dev
```

#### Problem: Dependency resolution failures
```
Error: Could not resolve dependency
Error: Module not found in cache
```

**Solution:**
```bash
# Check dependency graph
make tg-graph

# Reinitialize dependencies
terragrunt run-all init --terragrunt-working-dir live/

# Force refresh dependencies
terragrunt run-all plan --terragrunt-non-interactive --terragrunt-working-dir live/
```

### State Lock Issues

#### Problem: State locked by another process
```
Error: Error acquiring the state lock
Lock Info:
  ID:        12345-abcd-efgh
  Path:      path/to/state
  Operation: OperationTypePlan
```

**Solution:**
```bash
# Check if process is actually running
ps aux | grep terraform
ps aux | grep terragrunt

# Force unlock (use with caution)
cd live/dev
terragrunt force-unlock 12345-abcd-efgh

# Verify state consistency after unlock
terragrunt plan
```

### Version Compatibility Issues

#### Problem: Terragrunt version mismatch
```
Error: This version of Terragrunt requires Terraform >= 1.5
```

**Solution:**
```bash
# Check versions
terragrunt --version
terraform --version

# Update Terraform (Ubuntu/Debian)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Update Terragrunt
wget -O /tmp/terragrunt https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64
chmod +x /tmp/terragrunt
sudo mv /tmp/terragrunt /usr/local/bin/
```

## 🌐 Terraform Issues

### Authentication Problems

#### Problem: Infoblox provider authentication failure
```
Error: error creating Infoblox client: authentication failed
Error: Invalid credentials
```

**Solution:**
```bash
# Check environment variables
echo $INFOBLOX_SERVER
echo $INFOBLOX_USERNAME
echo $INFOBLOX_PASSWORD

# Set credentials (if missing)
export INFOBLOX_SERVER="https://infoblox.company.com"
export INFOBLOX_USERNAME="automation-user"
export INFOBLOX_PASSWORD="your-password"
export INFOBLOX_WAPI_VERSION="2.12"

# Test connectivity
curl -k -u $INFOBLOX_USERNAME:$INFOBLOX_PASSWORD \
  "$INFOBLOX_SERVER/wapi/v$INFOBLOX_WAPI_VERSION/grid"
```

#### Problem: SSL certificate verification issues
```
Error: certificate signed by unknown authority
Error: x509: certificate verify failed
```

**Solution:**
```bash
# Option 1: Disable SSL verification (development only)
export INFOBLOX_SSL_VERIFY=false

# Option 2: Add certificate to trust store
sudo cp infoblox-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Option 3: Configure in Terraform
# Add to terraform.tfvars:
cat >> terraform.tfvars << EOF
infoblox_ssl_verify = false
EOF
```

### Resource State Issues

#### Problem: Resource exists but not in state
```
Error: A resource with the ID "record:a/ZG5zLmJpbmRfYSQu..." already exists
```

**Solution:**
```bash
# Import existing resource
terragrunt import 'module.dns.infoblox_a_record.example' 'record:a/ZG5zLmJpbmRfYSQu...'

# Or remove from Infoblox and recreate
# This should be done carefully in production
```

#### Problem: State drift detected
```
Note: Objects have changed outside of Terraform
```

**Solution:**
```bash
# Refresh state from actual infrastructure
terragrunt refresh

# Check what changed
terragrunt plan

# Apply to reconcile differences (review carefully)
terragrunt apply
```

### Module and Configuration Issues

#### Problem: Module source not found
```
Error: Module not found
Error: Could not download module
```

**Solution:**
```bash
# Check module source paths in terragrunt.hcl
cat live/dev/terragrunt.hcl | grep source

# Verify module directory exists
ls -la modules/

# Reinitialize with module refresh
terragrunt init -upgrade
```

## 📝 Configuration Issues

### YAML Syntax Errors

#### Problem: YAML parsing errors
```
yaml.parser.ParserError: while parsing a block mapping
```

**Solution:**
```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('live/dev/configs/networks.yaml'))"

# Check all YAML files
for file in live/dev/configs/*.yaml; do
    echo "Checking $file"
    python3 -c "import yaml; yaml.safe_load(open('$file'))" || echo "Error in $file"
done

# Use online YAML validator for complex issues
# https://yamlchecker.com/
```

#### Problem: Invalid configuration schema
```
Error: Invalid configuration for resource
```

**Solution:**
```bash
# Validate configuration schema
./scripts/validate-config.sh dev

# Check configuration examples
ls live/dev/configs/
cat live/dev/configs/a-records.yaml

# Compare with documentation
cat docs/CONFIGURATION.md
```

### Environment Configuration Issues

#### Problem: Environment-specific variables not loading
```
Error: Variable not defined
Error: No value found for required variable
```

**Solution:**
```bash
# Check terragrunt.hcl configuration
cat live/dev/terragrunt.hcl

# Verify variable definitions
grep -r "variable" modules/

# Check environment variable passing
terragrunt plan --terragrunt-debug
```

## 🤖 Backstage Integration Issues

### Template Processing Issues

#### Problem: Backstage template validation failure
```
Template validation failed: Missing required parameter
```

**Solution:**
```bash
# Test template syntax
python3 -c "import yaml; yaml.safe_load(open('templates/backstage/ip-reservation-template.yaml'))"

# Run template tests
make test-backstage-ip

# Check template parameters
grep -A 20 "required:" templates/backstage/ip-reservation-template.yaml
```

#### Problem: Content generation errors
```
Error: Template rendering failed
```

**Solution:**
```bash
# Check content template syntax
cat templates/backstage/content/ip-reservations.yaml

# Validate template variables
grep '\${{' templates/backstage/content/ip-reservations.yaml

# Test template generation manually
# Use test data to verify template processing
```

### Resource Merge Conflicts

#### Problem: Configuration merge conflicts
```
Conflict detected: Resource exists in both manual and Backstage configurations
```

**Solution:**
```bash
# Check merge strategy options
python3 scripts/merge-backstage-config.py --help

# Use preview mode to see conflicts
python3 scripts/merge-backstage-config.py dev --dry-run

# Resolve with appropriate strategy
python3 scripts/merge-backstage-config.py dev --strategy manual-protected

# Available strategies:
# - backstage-wins: Backstage configuration takes precedence
# - manual-protected: Preserve manual configurations
# - timestamp-wins: Newest configuration wins
# - fail-on-conflict: Stop on any conflict
```

### Resource Tracking Issues

#### Problem: Backstage resource ID not found
```
Error: Resource ID not found in configurations
```

**Solution:**
```bash
# List all Backstage resources
python3 scripts/manage-backstage-resources.py \
  --config-path live/dev/configs \
  list

# Search for specific resource
python3 scripts/manage-backstage-resources.py \
  --config-path live/dev/configs \
  find my-app

# Validate ID format
python3 scripts/manage-backstage-resources.py \
  validate "my-app-dev-20250910140000"
```

## 🧪 Testing and Validation Issues

### Test Failures

#### Problem: Comprehensive tests failing
```
❌ Test failed: YAML valid: dev/networks.yaml
```

**Solution:**
```bash
# Run tests with verbose output
bash -x ./test-comprehensive.sh

# Run specific test categories
make test-makefile
make test-backstage-ip

# Check individual test components
./test-setup.sh
```

#### Problem: Template tests hanging or failing
```
Tests run: 0, Tests passed: 0, Tests failed: 0
```

**Solution:**
```bash
# Check test script permissions
ls -la tests/test-backstage-ip-reservations.sh

# Run with timeout
timeout 60 ./tests/test-backstage-ip-reservations.sh

# Debug test execution
bash -x ./tests/test-backstage-ip-reservations.sh
```

### Validation Errors

#### Problem: State validation failures
```
State validation failed: Inconsistent state detected
```

**Solution:**
```bash
# Run state validation
./scripts/backstage-cleanup.sh dev validate-state

# Check for state inconsistencies
terragrunt plan

# Refresh state if needed
terragrunt refresh
```

## 🔧 Script and Automation Issues

### Script Execution Problems

#### Problem: Permission denied errors
```bash
bash: ./scripts/terragrunt-deploy.sh: Permission denied
```

**Solution:**
```bash
# Fix script permissions
chmod +x scripts/*.sh
chmod +x tests/*.sh
chmod +x *.sh

# Verify permissions
ls -la scripts/
```

#### Problem: Missing dependencies
```bash
./scripts/manage-backstage-resources.py: No module named 'yaml'
```

**Solution:**
```bash
# Install Python dependencies
pip install PyYAML

# Check Python version
python3 --version

# Verify module installation
python3 -c "import yaml; print('PyYAML installed successfully')"
```

### Common Function Library Issues

#### Problem: Common functions not loading
```bash
source: scripts/common-functions.sh: No such file or directory
```

**Solution:**
```bash
# Check file exists
ls -la scripts/common-functions.sh

# Fix relative path issues
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/common-functions.sh"

# Or use absolute path
source "$(pwd)/scripts/common-functions.sh"
```

## 🌐 Network and Connectivity Issues

### Infoblox Connectivity

#### Problem: Cannot connect to Infoblox appliance
```bash
curl: (7) Failed to connect to infoblox.company.com port 443: Connection refused
```

**Solution:**
```bash
# Check network connectivity
ping infoblox.company.com

# Test port connectivity
telnet infoblox.company.com 443

# Check firewall rules
sudo iptables -L | grep 443

# Test with curl
curl -k https://infoblox.company.com/wapi/v2.12/grid
```

#### Problem: VPN connectivity issues
```bash
Error: Cannot reach Infoblox management interface
```

**Solution:**
```bash
# Check VPN status
ip route | grep vpn

# Test internal connectivity
ping infoblox.internal.company.com

# Restart VPN connection
sudo systemctl restart openvpn@company-automation
```

## 📋 Diagnostic Procedures

### System Diagnostics

#### Complete System Check
```bash
#!/bin/bash
# comprehensive-diagnostics.sh

echo "=== System Diagnostics ==="

# Check tools
echo "Checking required tools..."
for tool in terragrunt terraform python3 make git; do
    if command -v $tool >/dev/null 2>&1; then
        echo "✅ $tool: $(command -v $tool)"
    else
        echo "❌ $tool: Not found"
    fi
done

# Check Python modules
echo "Checking Python modules..."
python3 -c "import yaml; print('✅ PyYAML: Available')" 2>/dev/null || echo "❌ PyYAML: Missing"

# Check file permissions
echo "Checking script permissions..."
for script in scripts/*.sh; do
    if [[ -x "$script" ]]; then
        echo "✅ $script: Executable"
    else
        echo "❌ $script: Not executable"
    fi
done

# Check environment configurations
echo "Checking environment configurations..."
for env in dev staging prod; do
    if [[ -d "live/$env" ]]; then
        echo "✅ Environment $env: Exists"
        if [[ -f "live/$env/terragrunt.hcl" ]]; then
            echo "✅ Environment $env: Configuration exists"
        else
            echo "❌ Environment $env: Missing terragrunt.hcl"
        fi
    else
        echo "❌ Environment $env: Missing"
    fi
done

# Check YAML files
echo "Checking YAML syntax..."
for yaml_file in live/*/configs/*.yaml; do
    if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
        echo "✅ $yaml_file: Valid"
    else
        echo "❌ $yaml_file: Invalid"
    fi
done

echo "=== Diagnostics Complete ==="
```

### Performance Diagnostics

#### Check Resource Usage
```bash
# Monitor resource usage during operations
watch -n 1 'free -h && echo "---" && df -h && echo "---" && ps aux | grep -E "(terraform|terragrunt)" | head -5'

# Time operations
time make tg-plan ENV=dev

# Check disk space
df -h /tmp
df -h .
```

## 🆘 Emergency Procedures

### Emergency Rollback

#### Immediate Rollback Steps
```bash
# 1. Stop all running operations
pkill -f terraform
pkill -f terragrunt

# 2. Revert to last known good configuration
git log --oneline -10
git revert <bad-commit-hash>

# 3. Plan rollback
make tg-plan ENV=prod

# 4. Apply rollback (with approval)
make tg-apply ENV=prod

# 5. Verify rollback successful
make tg-output ENV=prod
```

### Emergency Contact Procedures

#### Escalation Process
1. **Level 1**: Development team (configuration issues)
2. **Level 2**: Infrastructure team (platform issues)
3. **Level 3**: Network team (Infoblox appliance issues)
4. **Level 4**: Vendor support (critical appliance issues)

#### Emergency Contacts
```bash
# Add to your emergency contact list
DEV_TEAM="dev-team@company.com"
INFRA_TEAM="infrastructure@company.com"
NETWORK_TEAM="network-ops@company.com"
VENDOR_SUPPORT="support@infoblox.com"
```

## 📞 Getting Help

### Before Requesting Support

1. **Run diagnostics**: `make test-comprehensive`
2. **Check logs**: Review terraform.log and terragrunt output
3. **Search documentation**: Check all docs/ files
4. **Review recent changes**: `git log --oneline -10`
5. **Test in development**: Try to reproduce in dev environment

### Information to Include in Support Requests

- **Environment**: dev/staging/prod
- **Error message**: Complete error output
- **Command executed**: Exact command that failed
- **Configuration**: Relevant configuration files
- **Logs**: Terraform/Terragrunt debug logs
- **System info**: OS, tool versions, network setup
- **Recent changes**: Git commits in last 24 hours

### Support Resources

- **Documentation**: Complete docs/ directory
- **Test Suite**: Run tests to verify functionality
- **Configuration Examples**: Reference live/ directories
- **GitHub Issues**: Report bugs and request features
- **Community**: Join discussions and share solutions

Remember: Most issues can be resolved by following this troubleshooting guide systematically. When in doubt, start with the basic diagnostic commands and work your way through the specific issue categories.
