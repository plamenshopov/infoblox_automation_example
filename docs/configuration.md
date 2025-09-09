# Configuration Reference

This document provides detailed information about all configuration options available in the Infoblox Terraform automation framework.

## Directory Structure

```
infoblox-automation/
├── environments/           # Environment-specific configurations
│   ├── dev/
│   │   ├── configs/       # YAML configuration files
│   │   ├── main.tf        # Environment Terraform config
│   │   ├── variables.tf   # Environment variables
│   │   ├── outputs.tf     # Environment outputs
│   │   └── terraform.tfvars.example
│   ├── staging/
│   └── prod/
├── modules/               # Reusable Terraform modules
│   ├── ipam/             # IPAM module
│   └── dns/              # DNS module
├── templates/            # Backstage templates
├── scripts/              # Automation scripts
└── docs/                 # Documentation
```

## Configuration Files

### Network Configuration (`networks.yaml`)

```yaml
network_name:
  network_view: string      # Network view name (usually "default")
  network: string          # Network CIDR (e.g., "10.1.0.0/24")
  comment: string          # Description of the network
  ea_tags:                 # Extensible attributes (optional)
    key: value
```

**Example:**
```yaml
production_web:
  network_view: "default"
  network: "10.1.0.0/24"
  comment: "Production web servers network"
  ea_tags:
    Department: "Engineering"
    Environment: "production"
    Purpose: "web-servers"
    Owner: "platform-team"
```

### DNS Zone Configuration (`dns-zones.yaml`)

```yaml
zone_name:
  zone: string            # Zone FQDN (e.g., "example.com")
  view: string            # DNS view name (usually "default")
  comment: string         # Description of the zone
  ea_tags:               # Extensible attributes (optional)
    key: value
```

**Example:**
```yaml
company_internal:
  zone: "internal.company.com"
  view: "default"
  comment: "Internal company domain"
  ea_tags:
    Environment: "production"
    Type: "internal"
    Owner: "dns-team"
```

### A Record Configuration (`a-records.yaml`)

```yaml
record_name:
  fqdn: string           # Fully qualified domain name
  ip_addr: string        # IP address
  view: string           # DNS view (optional, default: "default")
  ttl: number           # Time to live in seconds (optional, default: 3600)
  comment: string       # Description
  ea_tags:              # Extensible attributes (optional)
    key: value
```

**Example:**
```yaml
web_server_01:
  fqdn: "web01.company.com"
  ip_addr: "10.1.0.10"
  view: "default"
  ttl: 3600
  comment: "Primary web server"
  ea_tags:
    Server_Type: "web"
    Environment: "production"
    OS: "ubuntu"
    Owner: "web-team"
```

### CNAME Record Configuration (`cname-records.yaml`)

```yaml
alias_name:
  alias: string          # Alias FQDN
  canonical: string      # Target FQDN
  view: string          # DNS view (optional, default: "default")
  ttl: number           # Time to live in seconds (optional, default: 3600)
  comment: string       # Description
  ea_tags:              # Extensible attributes (optional)
    key: value
```

**Example:**
```yaml
www_alias:
  alias: "www.company.com"
  canonical: "web01.company.com"
  view: "default"
  ttl: 1800
  comment: "WWW alias for main website"
  ea_tags:
    Record_Type: "www_alias"
    Environment: "production"
    Owner: "web-team"
```

### Host Record Configuration (`host-records.yaml`)

```yaml
host_name:
  fqdn: string           # Fully qualified domain name
  ip_addr: string        # Static IP address (if allocate_ip: false)
  network: string        # Network CIDR for allocation (if allocate_ip: true)
  allocate_ip: boolean   # Whether to auto-allocate IP
  view: string          # DNS view (optional, default: "default")
  ttl: number           # Time to live in seconds (optional, default: 3600)
  comment: string       # Description
  ea_tags:              # Extensible attributes (optional)
    key: value
```

**Static IP Example:**
```yaml
database_server:
  fqdn: "db01.company.com"
  ip_addr: "10.1.0.20"
  allocate_ip: false
  view: "default"
  ttl: 3600
  comment: "Production database server"
  ea_tags:
    Server_Type: "database"
    Environment: "production"
    Owner: "database-team"
```

**Auto-allocated IP Example:**
```yaml
dynamic_app_server:
  fqdn: "app-auto.company.com"
  network: "10.1.1.0/24"
  allocate_ip: true
  view: "default"
  ttl: 1800
  comment: "Auto-allocated application server"
  ea_tags:
    Server_Type: "application"
    Allocation_Type: "automatic"
    Environment: "production"
    Owner: "app-team"
```

## Terraform Variables

### Provider Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `infoblox_username` | string | Infoblox NIOS username | - |
| `infoblox_password` | string | Infoblox NIOS password | - |
| `infoblox_server` | string | Infoblox server hostname/IP | - |
| `infoblox_ssl_verify` | bool | Enable SSL verification | true |

### Environment Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `environment` | string | Environment name | - |
| `project_name` | string | Project name | "infoblox-automation" |

## Extensible Attributes (Tags)

Extensible attributes are custom metadata that can be attached to Infoblox objects. Common tags include:

### Standard Tags

| Tag | Description | Example Values |
|-----|-------------|---------------|
| `Environment` | Environment name | dev, staging, prod |
| `Owner` | Responsible team/person | platform-team, john.doe |
| `Project` | Project name | web-app, api-service |
| `Department` | Department | Engineering, IT, Security |
| `Purpose` | Resource purpose | web-server, database, loadbalancer |
| `CostCenter` | Cost center code | CC-1001, CC-2002 |

### Server Tags

| Tag | Description | Example Values |
|-----|-------------|---------------|
| `Server_Type` | Type of server | web, database, api, cache |
| `OS` | Operating system | ubuntu, centos, windows |
| `Application` | Application name | nginx, mysql, redis |
| `Backup_Policy` | Backup policy | daily, weekly, none |

### Network Tags

| Tag | Description | Example Values |
|-----|-------------|---------------|
| `Network_Type` | Type of network | production, development, dmz |
| `VLAN_ID` | VLAN identifier | 100, 200, 300 |
| `Security_Zone` | Security zone | trusted, untrusted, dmz |

## Validation Rules

### FQDN Validation
- Must follow DNS naming conventions
- Maximum 253 characters
- Each label maximum 63 characters
- Only alphanumeric and hyphens
- Cannot start or end with hyphen

### IP Address Validation
- Must be valid IPv4 format
- Each octet 0-255
- No leading zeros

### Network CIDR Validation
- Must include subnet mask (/xx)
- Subnet mask 0-32
- Network address must be valid

### TTL Validation
- Minimum: 0 seconds
- Maximum: 2147483647 seconds
- Common values: 300, 1800, 3600, 86400

## Environment-Specific Configurations

### Development Environment
- SSL verification disabled by default
- Shorter TTL values (300-1800 seconds)
- Test networks (192.168.x.x, 10.x.x.x)
- Relaxed validation

### Staging Environment
- SSL verification enabled
- Production-like configuration
- Staging networks
- Full validation

### Production Environment
- SSL verification required
- Longer TTL values (3600+ seconds)
- Production networks
- Strict validation
- Change approval required

## Best Practices

### Naming Conventions

#### Networks
- Format: `{environment}_{purpose}_{sequence}`
- Example: `prod_web_01`, `dev_database_01`

#### DNS Records
- Use environment prefixes for non-production
- Example: `web01.dev.company.com`, `api.staging.company.com`

#### Host Records
- Descriptive names with purpose
- Example: `web01`, `db-primary`, `cache-01`

### Tagging Strategy

1. **Always include**:
   - Environment
   - Owner
   - Purpose

2. **Include when relevant**:
   - Department
   - CostCenter
   - Application

3. **Avoid**:
   - Sensitive information
   - Frequently changing data
   - Very long values

### Configuration Management

1. **File Organization**:
   - One record type per file
   - Logical grouping within files
   - Consistent formatting

2. **Change Management**:
   - Use pull requests
   - Include meaningful commit messages
   - Document changes in comments

3. **Version Control**:
   - Commit all configuration changes
   - Tag releases
   - Maintain changelog

## Troubleshooting

### Common Configuration Errors

#### Invalid YAML Syntax
```yaml
# Wrong - missing quotes
name: web-01.company.com

# Correct - quotes for special characters
name: "web-01.company.com"
```

#### Invalid IP Addresses
```yaml
# Wrong - invalid octet
ip_addr: "10.1.0.256"

# Correct
ip_addr: "10.1.0.10"
```

#### Missing Required Fields
```yaml
# Wrong - missing required fqdn
web_server:
  ip_addr: "10.1.0.10"

# Correct
web_server:
  fqdn: "web01.company.com"
  ip_addr: "10.1.0.10"
```

### Validation Commands

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('file.yaml'))"

# Validate configuration
./scripts/validate-config.sh dev

# Check Terraform syntax
terraform validate
```

## Advanced Configuration

### Multiple DNS Views

```yaml
internal_record:
  fqdn: "app.company.com"
  ip_addr: "10.1.0.10"
  view: "internal"

external_record:
  fqdn: "app.company.com"
  ip_addr: "203.0.113.10"
  view: "external"
```

### Network Containers

For large network deployments, use network containers:

```yaml
# In a separate network-containers.yaml file
datacenter_1:
  network_view: "default"
  cidr: "10.1.0.0/16"
  comment: "Datacenter 1 supernet"
  ea_tags:
    Location: "datacenter-1"
    Type: "container"
```

### Conditional Configuration

Use environment-specific overrides:

```yaml
# Base configuration
web_server:
  fqdn: "web01.company.com"
  ttl: 3600
  ea_tags:
    Environment: "{{ environment }}"
    
# Override in dev
{% if environment == "dev" %}
    Debug_Mode: "enabled"
{% endif %}
```
