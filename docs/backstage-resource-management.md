# Backstage Resource Management with Unique Identifiers

## Overview

This system implements unique identifiers for all resources created by Backstage, making it easy to track, manage, and clean up resources throughout their lifecycle.

## Unique Identifier System

### Backstage ID Format
Each resource created through Backstage gets a unique identifier with the format:
```
{entity-name}-{environment}-{timestamp}
```

**Example:** `my-app-dev-20250909120000`

Where:
- `entity-name`: User-defined entity name (e.g., "my-app", "web-service")
- `environment`: Target environment (dev, staging, prod)
- `timestamp`: Creation timestamp (YYYYMMDDHHmmss)

### Resource Tagging
All Backstage-created resources include these extensible attributes:

```yaml
ea_tags:
  Owner: "team-name"
  CreatedBy: "backstage"
  CreatedAt: "2025-09-09T12:00:00Z"
  BackstageId: "my-app-dev-20250909120000"
  BackstageEntity: "my-app"
```

## Benefits

### 🎯 **Easy Resource Identification**
- Quickly identify which resources belong to which Backstage entity
- Clear ownership and creation tracking
- Audit trail for compliance

### 🧹 **Simplified Cleanup**
- Remove all resources for a specific entity across environments
- Prevent accidental deletion of manually created resources
- Automated cleanup workflows

### 📊 **Resource Governance**
- Track resource usage by team/entity
- Implement cost allocation
- Monitor resource lifecycle

## Management Tools

### 1. Resource Discovery Script

```bash
# List all Backstage-created resources
./scripts/manage-backstage-resources.py list

# Filter by entity
./scripts/manage-backstage-resources.py list --entity my-app

# Find resources for specific entity
./scripts/manage-backstage-resources.py find my-app

# Output in different formats
./scripts/manage-backstage-resources.py list --format json
./scripts/manage-backstage-resources.py list --format yaml
```

### 2. Cleanup Script

```bash
# Remove all resources for an entity (with confirmation)
./scripts/cleanup-backstage-resources.sh --environment dev --entity-name my-app

# Remove specific resource by Backstage ID
./scripts/cleanup-backstage-resources.sh --environment dev --backstage-id my-app-dev-20250909120000

# Dry run to see what would be removed
./scripts/cleanup-backstage-resources.sh --environment dev --entity-name my-app --dry-run

# Force cleanup without confirmation
./scripts/cleanup-backstage-resources.sh --environment dev --entity-name my-app --force

# Use with Terragrunt
./scripts/cleanup-backstage-resources.sh --environment dev --entity-name my-app --terragrunt
```

## Backstage Template Changes

### Required Fields
The Backstage template now requires an additional field:

```yaml
entityName:
  title: Entity Name
  type: string
  description: Unique identifier for this Backstage entity (e.g., my-app, web-service)
  pattern: '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'
```

### Generated Configuration
Resources are now created with embedded tracking information:

```yaml
my_app_api:
  fqdn: "api.my-app.example.com"
  ip_addr: "10.1.1.100"
  comment: "API endpoint for my-app | Backstage ID: my-app-dev-20250909120000"
  ea_tags:
    Owner: "platform-team"
    CreatedBy: "backstage"
    BackstageId: "my-app-dev-20250909120000"
    BackstageEntity: "my-app"
    # ... other tags
```

## Workflow Integration

### GitHub Actions Enhancement
The CI/CD pipeline automatically recognizes Backstage-created resources and can:
- Skip validation for resources with valid Backstage IDs
- Generate deployment reports showing Backstage vs manual resources
- Implement approval workflows for resource cleanup

### Resource Lifecycle Management

1. **Creation**: Backstage generates unique ID and tags
2. **Tracking**: Resources are automatically discoverable
3. **Management**: Easy filtering and bulk operations
4. **Cleanup**: Safe removal with backup and confirmation

## Best Practices

### Entity Naming
- Use lowercase with hyphens: `my-app`, `web-service`
- Keep names descriptive but concise
- Follow your organization's naming conventions

### Resource Comments
- Always include descriptive comments
- Backstage ID is automatically appended
- Include purpose and context information

### Cleanup Procedures
1. **Always use dry-run first** to verify what will be removed
2. **Create backups** before major cleanup operations
3. **Coordinate with teams** before removing shared resources
4. **Document cleanup** in your change management system

## Example Scenarios

### Scenario 1: Decommissioning an Application
```bash
# 1. Find all resources for the application
./scripts/manage-backstage-resources.py find my-old-app

# 2. Check what would be removed (dry run)
./scripts/cleanup-backstage-resources.sh -e prod -n my-old-app --dry-run

# 3. Remove from staging first
./scripts/cleanup-backstage-resources.sh -e staging -n my-old-app

# 4. Remove from production (with confirmation)
./scripts/cleanup-backstage-resources.sh -e prod -n my-old-app
```

### Scenario 2: Environment Cleanup
```bash
# List all development resources
./scripts/manage-backstage-resources.py list | grep dev

# Clean up specific entities in development
./scripts/cleanup-backstage-resources.sh -e dev -n test-app-1
./scripts/cleanup-backstage-resources.sh -e dev -n test-app-2
```

### Scenario 3: Audit and Reporting
```bash
# Generate JSON report of all Backstage resources
./scripts/manage-backstage-resources.py list --format json > backstage-resources-audit.json

# Filter by specific team/owner
./scripts/manage-backstage-resources.py list --format json | jq '.[] | select(.owner == "platform-team")'
```

## Troubleshooting

### Invalid Backstage ID Format
```bash
# Validate ID format
./scripts/manage-backstage-resources.py validate my-app-dev-20250909120000
```

### Resource Not Found
- Check if resource was created manually (no BackstageId tag)
- Verify environment and entity name spelling
- Check if resource was already removed

### Cleanup Failures
- Ensure Terraform/Terragrunt state is synchronized
- Check Infoblox connectivity and credentials
- Verify resource dependencies (remove dependent resources first)

## Integration with Monitoring

### Alerting
Set up alerts for:
- Resources without proper Backstage tags
- Orphaned resources (entity no longer exists in Backstage)
- Resources older than defined retention periods

### Dashboards
Create dashboards showing:
- Resource count by entity and environment
- Creation/deletion trends
- Cost allocation by Backstage entity

This unique identifier system provides comprehensive resource governance while maintaining the flexibility to manage resources both through Backstage automation and manual processes.
