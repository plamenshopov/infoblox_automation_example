# Backstage Integration Guide

This guide explains how to integrate the Infoblox Terraform automation with Backstage for self-service DNS and IPAM provisioning.

## Overview

The Backstage integration provides:
- Self-service DNS record creation
- Automated pull request creation
- Approval workflows
- Git-based change tracking

## Setup

### 1. Install Backstage Templates

Copy the templates to your Backstage instance:

```bash
# Copy template files to your Backstage templates directory
cp -r templates/backstage/* /path/to/backstage/templates/
```

### 2. Register Templates

Add the template to your Backstage catalog:

```yaml
# In catalog-info.yaml
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: infoblox-templates
spec:
  targets:
    - ./templates/backstage/dns-record-template.yaml
```

### 3. Configure GitHub Integration

Ensure your Backstage instance has GitHub integration configured:

```yaml
# In app-config.yaml
github:
  - host: github.com
    token: ${GITHUB_TOKEN}

scaffolder:
  github:
    token: ${GITHUB_TOKEN}
```

## Using the Templates

### DNS Record Creation

1. Navigate to Backstage Software Templates
2. Select "Create Infoblox DNS Record"
3. Fill in the required information:
   - **Record Name**: FQDN of the record
   - **Record Type**: A, CNAME, or HOST
   - **Environment**: dev, staging, or prod
   - **IP Address**: For A records (optional for HOST)
   - **Network**: For HOST records with auto-allocation
   - **Owner**: Responsible team/person

4. Click "Create" to generate a pull request

### Approval Workflow

1. Template creates a pull request with the new configuration
2. Team reviews the changes
3. Automated validation runs
4. Upon approval and merge, changes are deployed

## Template Configuration

### DNS Record Template

The template supports three record types:

#### A Records
- Static IP address assignment
- Fixed FQDN to IP mapping
- Suitable for servers with known IPs

#### CNAME Records
- Alias creation
- Points to existing FQDNs
- Useful for service aliases

#### HOST Records
- Automatic IP allocation
- Dynamic IP assignment from network pools
- Ideal for ephemeral resources

### Customization

You can customize the templates by modifying:

#### `dns-record-template.yaml`
- Add new record types
- Modify validation rules
- Change default values
- Add custom fields

#### Template Content
- Modify the generated YAML structure
- Add custom tags
- Change naming conventions

## Advanced Features

### Custom Validations

Add custom validation to the template:

```yaml
properties:
  recordName:
    title: Record Name
    type: string
    pattern: '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$'
    minLength: 3
    maxLength: 253
```

### Environment-Specific Networks

Configure different networks per environment:

```yaml
# Template parameter
network:
  title: Network
  type: string
  enum:
    - "10.1.0.0/24"   # Dev network
    - "10.2.0.0/24"   # Staging network
    - "10.3.0.0/24"   # Prod network
  when:
    properties:
      environment:
        enum: ["dev", "staging", "prod"]
```

### Automated Deployment

Set up GitHub Actions to automatically deploy approved changes:

```yaml
# .github/workflows/deploy.yml
name: Deploy Infoblox Changes
on:
  push:
    branches: [main]
    paths: ['environments/*/configs/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      - name: Deploy Changes
        run: |
          # Determine changed environment
          CHANGED_ENV=$(git diff --name-only HEAD~1 | grep -o 'environments/[^/]*' | head -1 | cut -d'/' -f2)
          if [ ! -z "$CHANGED_ENV" ]; then
            ./scripts/deploy.sh $CHANGED_ENV apply
          fi
```

## Monitoring and Alerts

### Deployment Notifications

Configure Slack notifications for deployments:

```yaml
# In GitHub Actions
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: "Infoblox deployment completed for ${{ env.ENVIRONMENT }}"
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Error Handling

Add error handling to templates:

```yaml
steps:
  - id: validate
    name: Validate Configuration
    action: debug:log
    input:
      message: "Validating DNS record configuration..."
      
  - id: create-pr
    name: Create Pull Request
    action: publish:github:pull-request
    input:
      # ... configuration
    onError:
      message: "Failed to create pull request. Please contact the platform team."
```

## Security Considerations

### Access Control

- Limit template access by team/role
- Implement approval requirements for production
- Use environment-specific credentials
- Audit all changes

### Credential Management

- Store Infoblox credentials in secure vaults
- Use service accounts for automation
- Rotate credentials regularly
- Monitor API access

### Change Approval

Implement multi-level approval for sensitive environments:

```yaml
# GitHub branch protection rules
protection_rules:
  production:
    required_reviews: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_status_checks:
      - validation
      - security-scan
```

## Troubleshooting

### Common Issues

#### Template Not Showing
- Check catalog registration
- Verify template syntax
- Review Backstage logs

#### Pull Request Creation Fails
- Verify GitHub token permissions
- Check repository access
- Validate template parameters

#### Validation Errors
- Review configuration syntax
- Check naming conventions
- Verify network/IP ranges

### Debugging

Enable debug logging in templates:

```yaml
steps:
  - id: debug
    name: Debug Information
    action: debug:log
    input:
      message: |
        Environment: ${{ parameters.environment }}
        Record Type: ${{ parameters.recordType }}
        Record Name: ${{ parameters.recordName }}
```

## Best Practices

### Template Design
- Keep templates simple and focused
- Provide clear descriptions and help text
- Use sensible defaults
- Implement proper validation

### Change Management
- Use pull requests for all changes
- Require reviews for production
- Implement automated testing
- Document all modifications

### User Experience
- Provide clear error messages
- Include helpful tooltips
- Use progressive disclosure
- Test user workflows regularly

## Integration Examples

### ServiceNow Integration

Connect with ServiceNow for change management:

```yaml
steps:
  - id: create-change-request
    name: Create ServiceNow Change Request
    action: servicenow:create-change
    input:
      summary: "DNS record creation: ${{ parameters.recordName }}"
      description: "Automated DNS record creation via Backstage"
      environment: ${{ parameters.environment }}
```

### Monitoring Integration

Integrate with monitoring systems:

```yaml
steps:
  - id: create-monitoring
    name: Create Monitoring Alert
    action: datadog:create-monitor
    input:
      name: "DNS resolution for ${{ parameters.recordName }}"
      type: "dns"
      query: "dns.response_time{host:${{ parameters.recordName }}}"
```
