# Resource Cleanup Guide

This guide explains how to safely clean up Infoblox resources provisioned through Backstage integration.

## Overview

The repository provides several cleanup options ranging from targeted resource removal to full environment destruction. **Always prefer targeted cleanup over environment-wide destruction.**

## Cleanup Options

### 1. List Backstage Resources (Safe)

View all resources managed by Backstage in an environment:

```bash
make backstage-list ENV=dev
```

This shows:
- Resource IDs
- Entity names
- IP addresses
- DNS records
- Creation timestamps

### 2. Preview Cleanup (Safe)

Preview what would be removed without making changes:

```bash
# Preview removal by entity name
make backstage-preview-entity ENV=dev ENTITY=my-application

# Preview removal by resource ID
make backstage-preview-id ENV=dev ID=backstage-20240101-120000-abcd1234
```

### 3. Targeted Cleanup (Recommended)

Remove specific resources by entity or ID:

```bash
# Remove all resources for a specific application
make backstage-cleanup-entity ENV=dev ENTITY=my-application

# Remove a specific resource by ID
make backstage-cleanup-id ENV=dev ID=backstage-20240101-120000-abcd1234
```

**Safety Features:**
- Automatic backup before changes
- Confirmation prompts
- Validation of parameters
- Preview mode available

### 4. Environment Destruction (Dangerous)

⚠️ **Only use in exceptional circumstances**

```bash
make tg-destroy ENV=dev
```

This will:
- Destroy ALL resources in the environment
- Remove both Backstage AND manually created resources
- Require explicit confirmation with environment name

## Workflow Examples

### Removing a Decommissioned Application

1. **List resources** to identify what will be removed:
   ```bash
   make backstage-list ENV=prod
   ```

2. **Preview cleanup** to verify scope:
   ```bash
   make backstage-preview-entity ENV=prod ENTITY=legacy-app
   ```

3. **Execute cleanup** after verification:
   ```bash
   make backstage-cleanup-entity ENV=prod ENTITY=legacy-app
   ```

### Removing a Specific Resource

1. **Find the resource ID** from the list:
   ```bash
   make backstage-list ENV=dev | grep my-service
   ```

2. **Preview the removal**:
   ```bash
   make backstage-preview-id ENV=dev ID=backstage-20240315-140000-xyz789
   ```

3. **Execute the removal**:
   ```bash
   make backstage-cleanup-id ENV=dev ID=backstage-20240315-140000-xyz789
   ```

## Safety Best Practices

### Before Cleanup
- Always run preview first
- Verify you're targeting the correct environment
- Check with application owners before removing resources
- Ensure no active dependencies exist

### During Cleanup
- Read confirmation prompts carefully
- Verify the environment and scope
- Have backups ready (automatically created)
- Monitor for errors during execution

### After Cleanup
- Verify resources are properly removed
- Check for any orphaned dependencies
- Update documentation if needed
- Inform stakeholders of changes

## Backup and Recovery

### Automatic Backups
All cleanup operations automatically create backups:
- Location: `backups/backstage-configs-{timestamp}.tar.gz`
- Contains: Complete configuration state before changes
- Retention: Manual cleanup required

### Manual Backup
Create a backup before major changes:
```bash
./scripts/backup-configs.sh dev
```

### Recovery
Restore from backup if needed:
```bash
# Extract backup
tar -xzf backups/backstage-configs-20240315-140000.tar.gz

# Review and selectively restore configurations
# (Manual process - review changes carefully)
```

## Troubleshooting

### Common Issues

**"Resource not found"**
- Verify the resource ID or entity name
- Check if resource was already removed
- Ensure you're in the correct environment

**"Permission denied"**
- Check Infoblox credentials
- Verify environment configuration
- Ensure proper access to state backend

**"Terraform state conflicts"**
- Run `terragrunt state pull` to check current state
- Consider manual cleanup if automated removal fails
- Check for resource dependencies

### Recovery Steps
1. Check backup files in `backups/` directory
2. Review Terragrunt state: `terragrunt state list`
3. Validate Infoblox GUI for actual resource status
4. Use manual cleanup if automation fails

## Environment-Specific Notes

### Development (`dev`)
- More permissive cleanup policies
- Faster iteration cycles
- Regular cleanup recommended

### Staging (`staging`)
- Coordinate with testing teams
- Validate impact on integration tests
- Schedule cleanup during maintenance windows

### Production (`prod`)
- Require change management approval
- Implement additional confirmation steps
- Always test in lower environments first
- Document all changes

## Integration with Backstage

### Entity Management
- Resources tagged with Backstage entity names
- Automatic cleanup when applications are decommissioned
- Integration with Backstage lifecycle management

### Resource Tracking
- Unique IDs for all Backstage-created resources
- Audit trail in configuration files
- Integration with monitoring systems

## Monitoring and Alerting

### Post-Cleanup Validation
```bash
# Verify removal
make backstage-list ENV=dev | grep -i "entity-name"

# Check Infoblox GUI
# Verify DNS resolution
nslookup removed-record.example.com

# Check IP allocation
ping removed-ip-address
```

### Alerting Setup
Consider implementing:
- Notification when resources are removed
- Monitoring for orphaned resources
- Regular cleanup reports
- Integration with change management systems
