# Getting Started with Infoblox Terraform Automation

This guide will help you get started with the Infoblox Terraform automation framework.

## Prerequisites

### Required Software
- [Terraform](https://www.terraform.io/) >= 1.0
- [Git](https://git-scm.com/)
- Python 3.x (for validation scripts)
- PyYAML (`pip install PyYAML`)

### Infoblox Requirements
- Infoblox NIOS Grid Manager
- API access credentials (username/password)
- Network access to the Infoblox appliance

## Initial Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd infoblox-automation
```

### 2. Configure Backend Storage
Edit `versions.tf` to configure your Terraform backend:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "infoblox/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-lock"
}
```

### 3. Environment Configuration
Choose your target environment and configure credentials:

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your Infoblox connection details:
```hcl
infoblox_username   = "admin"
infoblox_password   = "your-password"
infoblox_server     = "infoblox.company.com"
infoblox_ssl_verify = true
```

### 4. Configure Resources

#### Networks
Edit `environments/dev/configs/networks.yaml`:
```yaml
my_network:
  network_view: "default"
  network: "10.1.0.0/24"
  comment: "My test network"
  ea_tags:
    Department: "IT"
    Purpose: "Development"
```

#### DNS Zones
Edit `environments/dev/configs/dns-zones.yaml`:
```yaml
my_zone:
  zone: "dev.company.com"
  view: "default"
  comment: "Development zone"
  ea_tags:
    Environment: "dev"
```

#### A Records
Edit `environments/dev/configs/a-records.yaml`:
```yaml
web_server:
  fqdn: "web01.dev.company.com"
  ip_addr: "10.1.0.10"
  view: "default"
  ttl: 3600
  comment: "Web server"
  ea_tags:
    Server_Type: "web"
```

## Deployment

### 1. Validate Configuration
Before deploying, validate your configuration:
```bash
./scripts/validate-config.sh dev
```

### 2. Plan Deployment
Review what will be created:
```bash
./scripts/deploy.sh dev plan
```

### 3. Apply Changes
Deploy the resources:
```bash
./scripts/deploy.sh dev apply
```

### 4. Verify Resources
Check the Infoblox Grid Manager to verify resources were created correctly.

## Common Operations

### Adding a New DNS Record
1. Edit the appropriate configuration file
2. Validate the configuration
3. Plan and apply the changes

Example adding an A record:
```yaml
# In a-records.yaml
new_server:
  fqdn: "app01.dev.company.com"
  ip_addr: "10.1.0.20"
  view: "default"
  ttl: 3600
  comment: "Application server"
  ea_tags:
    Server_Type: "application"
    Owner: "App Team"
```

### Adding a New Network
1. Edit `networks.yaml`
2. Add corresponding DNS records if needed
3. Deploy changes

Example:
```yaml
# In networks.yaml
app_network:
  network_view: "default"
  network: "10.2.0.0/24"
  comment: "Application network"
  ea_tags:
    Department: "Development"
    Purpose: "Applications"
```

## Troubleshooting

### Common Issues

#### Authentication Errors
- Verify credentials in `terraform.tfvars`
- Check network connectivity to Infoblox
- Ensure API access is enabled

#### Resource Already Exists
- Check if resources were created outside Terraform
- Import existing resources or use different names

#### Network/IP Conflicts
- Verify network ranges don't overlap
- Check IP address assignments
- Review IPAM policies in Infoblox

### Getting Help

1. Check the logs for detailed error messages
2. Validate configuration with `validate-config.sh`
3. Review Terraform plan output carefully
4. Check Infoblox Grid Manager for conflicts

## Best Practices

### Configuration Management
- Use descriptive names for resources
- Include meaningful comments
- Tag resources appropriately
- Follow naming conventions

### Security
- Store credentials securely
- Use environment-specific accounts when possible
- Enable SSL verification in production
- Restrict API access

### Version Control
- Commit configuration changes
- Use pull requests for review
- Tag releases
- Document changes

## Next Steps

- [Module Documentation](modules.md) - Learn about available modules
- [Backstage Integration](backstage.md) - Set up automated provisioning
- [Configuration Reference](configuration.md) - Detailed configuration options
