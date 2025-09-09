# Security Best Practices

Comprehensive security guidelines and best practices for the Infoblox Terraform Automation Platform.

## 🛡️ Overview

Security is a fundamental aspect of infrastructure automation. This guide covers all security considerations from credential management to deployment security, ensuring your Infoblox automation platform maintains the highest security standards.

## 🔐 Credential Management

### Core Principles
- **Never commit credentials** to version control
- **Use environment variables** for sensitive data
- **Implement credential rotation** policies
- **Use secure credential storage** (Azure Key Vault, HashiCorp Vault, AWS Secrets Manager)

### Infoblox API Credentials

#### Secure Storage
```bash
# Environment variables (recommended)
export INFOBLOX_SERVER="https://infoblox.company.com"
export INFOBLOX_USERNAME="automation-user"
export INFOBLOX_PASSWORD="secure-password"
export INFOBLOX_WAPI_VERSION="2.12"

# Azure Key Vault integration
az keyvault secret set \
  --vault-name "company-automation-vault" \
  --name "infoblox-password" \
  --value "secure-password"

# Retrieve from vault in scripts
INFOBLOX_PASSWORD=$(az keyvault secret show \
  --vault-name "company-automation-vault" \
  --name "infoblox-password" \
  --query value -o tsv)
```

#### Credential File Structure
```bash
# .env file (never commit to git)
# Add to .gitignore
INFOBLOX_SERVER=https://infoblox.company.com
INFOBLOX_USERNAME=automation-user
INFOBLOX_PASSWORD=secure-password
INFOBLOX_WAPI_VERSION=2.12

# Load in scripts
if [[ -f .env ]]; then
    source .env
fi
```

#### API Account Security
- **Dedicated service accounts** for automation
- **Minimum required permissions** (IPAM, DNS only)
- **Regular password rotation** (quarterly recommended)
- **Account monitoring** and audit logging
- **Disable interactive login** for service accounts

### Terraform State Security

#### State Encryption
```hcl
# terragrunt.hcl - Remote state configuration
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "companyterraformstate"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    
    # Security settings
    use_azuread_auth = true
    encrypt         = true
  }
}
```

#### State Access Control
```bash
# Azure RBAC for state storage
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee "automation-service-principal" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/terraform-state-rg"

# Separate permissions per environment
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee "dev-team-group" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/terraform-state-rg/providers/Microsoft.Storage/storageAccounts/terraformstate/blobServices/default/containers/dev"
```

## 🔒 Access Control

### Environment-Based Access

#### Development Environment
- **Full access** for development team
- **Read/write permissions** for all resources
- **Unrestricted deployment** capabilities
- **Learning and experimentation** encouraged

#### Staging Environment
- **Limited access** to senior developers
- **Pre-production testing** only
- **Approval required** for significant changes
- **Production-like security** controls

#### Production Environment
- **Restricted access** to operations team
- **Multi-person approval** required
- **Change management** process mandatory
- **Full audit logging** enabled
- **Emergency access** procedures defined

### Role-Based Access Control (RBAC)

#### GitHub Repository Access
```yaml
# .github/CODEOWNERS
# Production environment requires admin approval
live/prod/     @company/infrastructure-admins
docs/          @company/documentation-team
*.md           @company/documentation-team

# Sensitive files require security review
scripts/       @company/security-team @company/infrastructure-team
Makefile       @company/infrastructure-admins
```

#### Branch Protection Rules
```yaml
# GitHub branch protection (configure via UI or API)
protection_rules:
  main:
    required_reviews: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_status_checks:
      - "test-comprehensive"
      - "security-scan"
    restrictions:
      - "@company/infrastructure-admins"
  
  production:
    required_reviews: 3
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_status_checks:
      - "test-comprehensive"
      - "security-scan"
      - "compliance-check"
    restrictions:
      - "@company/infrastructure-admins"
```

### Infoblox NIOS Permissions

#### Service Account Permissions
```
Required Permissions:
- IPAM: Read, Write, Delete (for managed networks only)
- DNS: Read, Write, Delete (for managed zones only)
- DHCP: Read only (for validation)
- Reporting: Read only (for monitoring)

Restricted Permissions:
- Grid Administration: Denied
- User Management: Denied
- Appliance Management: Denied
- System Configuration: Denied
```

#### Network Segmentation
- **Management network** access only
- **VPN required** for external access
- **IP allow-listing** for automation hosts
- **Certificate-based authentication** where possible

## 🔍 Audit and Monitoring

### Logging Requirements

#### Infrastructure Changes
```bash
# All infrastructure changes must be logged
log_infrastructure_change() {
    local action="$1"
    local resource="$2"
    local environment="$3"
    local user="$4"
    
    logger -t "infoblox-automation" \
        "ACTION=$action RESOURCE=$resource ENV=$environment USER=$user TIMESTAMP=$(date -Iseconds)"
}

# Example usage in scripts
log_infrastructure_change "CREATE" "A-record-web-server" "prod" "$USER"
```

#### Access Logging
```bash
# Log all access to sensitive operations
audit_access() {
    local operation="$1"
    local environment="$2"
    
    echo "$(date -Iseconds) USER=$USER OPERATION=$operation ENV=$environment" >> /var/log/infoblox-access.log
}
```

### Monitoring and Alerting

#### GitHub Actions Security
```yaml
# .github/workflows/security-monitoring.yml
name: Security Monitoring
on:
  push:
    paths:
      - 'live/prod/**'
      - 'scripts/**'
      - 'Makefile'

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Secrets Scanning
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          
      - name: Security Policy Check
        run: |
          # Check for hardcoded credentials
          if grep -r "password\|secret\|key" --include="*.tf" --include="*.yaml" .; then
            echo "Potential credentials found"
            exit 1
          fi
          
      - name: Notify Security Team
        if: failure()
        uses: 8398a7/action-slack@v3
        with:
          status: failure
          channel: '#security-alerts'
```

### Compliance and Auditing

#### Change Documentation
```bash
# Required documentation for all changes
create_change_record() {
    cat > "changes/change-$(date +%Y%m%d-%H%M%S).md" << EOF
# Infrastructure Change Record

**Date**: $(date -Iseconds)
**User**: $USER
**Environment**: $ENVIRONMENT
**Change Type**: $CHANGE_TYPE

## Description
$CHANGE_DESCRIPTION

## Resources Modified
$RESOURCES_MODIFIED

## Risk Assessment
$RISK_ASSESSMENT

## Rollback Plan
$ROLLBACK_PLAN

## Approval
- [ ] Technical Review: 
- [ ] Security Review: 
- [ ] Management Approval: 
EOF
}
```

## 🚨 Incident Response

### Security Incident Procedures

#### Immediate Response
1. **Isolate affected systems** (disable API accounts)
2. **Assess impact** (check audit logs)
3. **Notify stakeholders** (security team, management)
4. **Document incident** (timeline, actions taken)
5. **Implement containment** (revoke credentials, block access)

#### Investigation Steps
```bash
# Check for unauthorized access
grep "FAILED\|ERROR\|UNAUTHORIZED" /var/log/infoblox-access.log

# Review recent changes
git log --since="24 hours ago" --oneline

# Check for credential exposure
trufflehog --regex --entropy=False .

# Validate current state
make validate-state ENV=prod
```

#### Recovery Procedures
```bash
# Credential rotation procedure
rotate_infoblox_credentials() {
    # 1. Generate new credentials in Infoblox
    # 2. Update credential storage (Key Vault)
    # 3. Test connectivity with new credentials
    # 4. Update all automation systems
    # 5. Disable old credentials
    # 6. Verify all systems operational
}

# Emergency access revocation
emergency_access_revocation() {
    # 1. Disable service accounts in Infoblox
    # 2. Revoke GitHub access tokens
    # 3. Rotate storage account keys
    # 4. Update all credential references
    # 5. Test critical functionality
}
```

## 🔧 Security Configuration

### Pipeline Security

#### GitHub Actions Security
```yaml
# Secure workflow configuration
env:
  # Use GitHub secrets for sensitive data
  INFOBLOX_SERVER: ${{ secrets.INFOBLOX_SERVER }}
  INFOBLOX_USERNAME: ${{ secrets.INFOBLOX_USERNAME }}
  INFOBLOX_PASSWORD: ${{ secrets.INFOBLOX_PASSWORD }}

permissions:
  # Minimum required permissions
  contents: read
  pull-requests: write
  id-token: write  # For OIDC

jobs:
  deploy:
    # Use approved runner images only
    runs-on: ubuntu-latest
    
    # Environment protection rules
    environment: production
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4  # Pin to specific version
        
      - name: Validate checksums
        run: |
          # Verify no unauthorized changes
          sha256sum -c checksums.txt
```

#### Secrets Management
```bash
# GitHub CLI secrets management
gh secret set INFOBLOX_PASSWORD --body "secure-password" --repo company/infoblox-automation

# Environment-specific secrets
gh secret set INFOBLOX_PROD_PASSWORD --body "prod-password" --repo company/infoblox-automation
gh secret set INFOBLOX_STAGING_PASSWORD --body "staging-password" --repo company/infoblox-automation
```

### Network Security

#### Firewall Rules
```bash
# Infoblox appliance access control
# Allow only specific source IPs/networks

# GitHub Actions runners (if using self-hosted)
iptables -A INPUT -s github-runner-network/24 -p tcp --dport 443 -j ACCEPT

# Automation hosts
iptables -A INPUT -s automation-subnet/24 -p tcp --dport 443 -j ACCEPT

# Management access
iptables -A INPUT -s management-network/24 -p tcp --dport 443 -j ACCEPT

# Deny all other access
iptables -A INPUT -p tcp --dport 443 -j DROP
```

#### VPN Configuration
```bash
# Require VPN for all external access
# Configure VPN client on automation hosts
openvpn --config company-automation.ovpn

# Verify VPN connectivity before operations
ping -c 3 infoblox.internal.company.com || exit 1
```

## 📋 Security Checklist

### Pre-Deployment Security Review
- [ ] **No hardcoded credentials** in code
- [ ] **Secrets properly stored** in secure vault
- [ ] **Minimum permissions** configured
- [ ] **Audit logging** enabled
- [ ] **Network access** properly restricted
- [ ] **Branch protection** rules in place
- [ ] **Required approvals** configured
- [ ] **Security scanning** passed
- [ ] **Compliance requirements** met
- [ ] **Incident response** plan updated

### Operational Security Checklist
- [ ] **Regular credential rotation** (quarterly)
- [ ] **Access review** (monthly)
- [ ] **Audit log review** (weekly)
- [ ] **Security patch updates** (as available)
- [ ] **Backup verification** (weekly)
- [ ] **Incident response testing** (annually)
- [ ] **Security training** (annually)
- [ ] **Compliance audit** (annually)

### Code Security Checklist
- [ ] **No secrets in code** (automated scan)
- [ ] **Input validation** implemented
- [ ] **Error handling** doesn't expose sensitive data
- [ ] **Logging** doesn't include credentials
- [ ] **Dependencies** scanned for vulnerabilities
- [ ] **Code review** completed by security team
- [ ] **Static analysis** passed
- [ ] **Dynamic testing** completed

## 🛠️ Security Tools and Automation

### Automated Security Scanning
```bash
# Secrets scanning with TruffleHog
trufflehog --regex --entropy=False --include_paths="scripts/,live/" .

# Dependency scanning
pip-audit --desc requirements.txt

# Code quality and security
bandit -r scripts/
pylint scripts/*.py

# Infrastructure security scanning
checkov -f live/
tfsec live/
```

### Security Monitoring Scripts
```bash
#!/bin/bash
# security-monitor.sh

# Check for unauthorized changes
check_unauthorized_changes() {
    local changes=$(git log --since="1 hour ago" --oneline)
    if [[ -n "$changes" ]]; then
        echo "Recent changes detected:"
        echo "$changes"
        # Alert security team
    fi
}

# Monitor credential usage
monitor_credential_usage() {
    local failed_auth=$(grep "401\|403" /var/log/infoblox-access.log | tail -10)
    if [[ -n "$failed_auth" ]]; then
        echo "Authentication failures detected"
        # Alert security team
    fi
}

# Run monitoring checks
check_unauthorized_changes
monitor_credential_usage
```

## 🎯 Security Best Practices Summary

### Critical Security Controls
1. **Multi-factor authentication** for all human access
2. **Service account isolation** with minimum permissions
3. **Encrypted state storage** with access logging
4. **Network segmentation** and firewall controls
5. **Regular credential rotation** and monitoring
6. **Comprehensive audit logging** and alerting
7. **Incident response procedures** and testing
8. **Security awareness training** for all team members

### Environment-Specific Security
- **Development**: Focus on learning and secure coding practices
- **Staging**: Pre-production security validation and testing
- **Production**: Maximum security controls and monitoring

### Continuous Security Improvement
- **Regular security assessments** and penetration testing
- **Security metrics** tracking and reporting
- **Threat modeling** for new features and changes
- **Security automation** and tooling improvements
- **Industry best practices** adoption and adaptation

This comprehensive security framework ensures that your Infoblox automation platform maintains the highest security standards while enabling efficient infrastructure management.
