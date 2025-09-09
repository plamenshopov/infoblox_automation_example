# IP Address Reservation Backstage Template

This document describes the Backstage template for creating IP address reservations in Infoblox IPAM without creating DNS records.

## Overview

The IP reservation Backstage template (`ip-reservation-template.yaml`) provides a self-service interface for teams to reserve IP addresses for various use cases including:

- Hardware devices (printers, switches, access points)
- IoT devices
- Load balancers and VIPs
- Container networking pools
- DHCP reservations
- Gateway addresses
- IP ranges for specific purposes

## Template Features

### 🔑 Unique Identifiers

Every IP reservation created through this template gets:

- **Reservation ID**: `ip-res-YYYYMMDDHHMMSS-{entityName}` - Globally unique identifier
- **Backstage ID**: `{entityName}-{environment}-YYYYMMDDHHMMSS` - Links to Backstage entity
- **Traceability**: Full audit trail from creation to deployment

### 📋 Reservation Types

The template supports 8 different reservation types:

| Type | Use Case | Required Fields | Description |
|------|----------|----------------|-------------|
| `fixed_address` | Devices with known MAC | IP + MAC | Reserve specific IP for specific MAC address |
| `ip_range` | Bulk IP allocation | Start IP + End IP | Reserve a range of consecutive IPs |
| `next_available` | Auto-assignment | Pool Size | Let Infoblox assign next available IPs |
| `static_ip` | Simple IP reservation | IP Address | Reserve specific IP without MAC binding |
| `vip` | Load balancers/clusters | IP Address | Virtual IP for high availability |
| `container_pool` | Container networking | Pool Size | IP pool for container orchestration |
| `dhcp_reservation` | DHCP with MAC | MAC Address | DHCP reservation for specific device |
| `gateway_reservation` | Network gateways | IP Address | Reserve gateway addresses |

### 🎛️ Configuration Parameters

#### Required Parameters
- **Entity Name**: Backstage entity identifier (lowercase, alphanumeric with hyphens)
- **Reservation Name**: Descriptive name for the reservation
- **Reservation Type**: One of the 8 supported types
- **Environment**: Target environment (dev/staging/prod)
- **Network CIDR**: Target network for the reservation

#### Type-Specific Parameters
- **IP Address**: Required for `fixed_address`, `static_ip`, `vip`, `gateway_reservation`
- **MAC Address**: Required for `fixed_address`, `dhcp_reservation`
- **IP Range**: Start/End IPs required for `ip_range`
- **Pool Size**: Required for `container_pool`, `next_available`

#### Optional Parameters
- **Comment**: Description of the reservation purpose
- **Owner**: Team or person responsible
- **Usage Type**: DNS/DHCP/UNSPECIFIED
- **Disable Discovery**: Prevent network discovery
- **Tags**: Additional metadata (Department, Purpose, Cost Center, Device Type, Location)

## Usage

### 1. Access Backstage Template

Navigate to Backstage Software Catalog → Create Component → IP Address Reservation

### 2. Fill Required Information

```yaml
# Example: Reserve IP for office printer
Entity Name: office-printer-01
Reservation Name: HP LaserJet Pro Office Printer
Reservation Type: fixed_address
Environment: prod
Network CIDR: 10.1.100.0/24
IP Address: 10.1.100.50
MAC Address: 00:11:22:33:44:55
```

### 3. Template Generates

The template creates a pull request with:

```yaml
ip_reservations:
  - id: "ip-res-20250910143000-office-printer-01"
    name: "HP LaserJet Pro Office Printer"
    type: "fixed_address"
    network: "10.1.100.0/24"
    ip_address: "10.1.100.50"
    mac_address: "00:11:22:33:44:55"
    comment: "Office printer reservation | Reservation ID: ip-res-20250910143000-office-printer-01"
    disable_discovery: false
    usage_type: "UNSPECIFIED"
    ea_tags:
      ReservationId: "ip-res-20250910143000-office-printer-01"
      BackstageId: "office-printer-01-prod-20250910143000"
      BackstageEntity: "office-printer-01"
      Owner: "facilities-team"
      CreatedBy: "john.doe"
      CreatedAt: "2025-09-10T14:30:00Z"
      ReservationType: "fixed_address"
      Environment: "prod"
      DeviceType: "Printer"
      Location: "Office Floor 3"
```

### 4. Review and Merge

1. Review the generated configuration in the pull request
2. Validate the IP doesn't conflict with existing reservations
3. Merge the pull request
4. Terragrunt will apply the changes automatically

## Use Case Examples

### Example 1: IoT Device Pool

```yaml
Entity Name: iot-sensors-pool
Reservation Type: next_available
Network: 10.1.200.0/24
Pool Size: 50
Environment: prod
Purpose: Temperature sensors for building automation
```

### Example 2: Load Balancer VIP

```yaml
Entity Name: web-app-lb
Reservation Type: vip
Network: 10.1.10.0/24
IP Address: 10.1.10.100
Environment: prod
Purpose: Load balancer virtual IP for web application
```

### Example 3: Container Network Pool

```yaml
Entity Name: k8s-pod-network
Reservation Type: container_pool
Network: 10.2.0.0/16
Pool Size: 100
Environment: staging
Purpose: Kubernetes pod networking
```

### Example 4: IP Range for Department

```yaml
Entity Name: engineering-range
Reservation Type: ip_range
Network: 10.1.50.0/24
Start IP: 10.1.50.100
End IP: 10.1.50.150
Environment: dev
Purpose: Engineering team development servers
```

## Tracking and Management

### Finding Your Reservations

```bash
# Find by Reservation ID
grep "ip-res-20250910143000-office-printer-01" live/*/configs/ip-reservations.yaml

# Find by Entity Name
grep "office-printer-01" live/*/configs/ip-reservations.yaml

# Find by Backstage ID
grep "office-printer-01-prod-20250910143000" live/*/configs/ip-reservations.yaml
```

### Validation and Testing

```bash
# Test the template
make test-backstage-ip

# Validate configuration
make validate ENV=prod

# Plan changes
make tg-plan ENV=prod
```

### Monitoring in Infoblox

Each reservation includes extensible attributes for easy filtering:

- **ReservationId**: Unique identifier for tracking
- **BackstageEntity**: Links back to Backstage entity
- **Environment**: dev/staging/prod
- **CreatedBy**: Who created the reservation
- **ReservationType**: Type of reservation

## File Structure

```
templates/backstage/
├── ip-reservation-template.yaml    # Main Backstage template
└── content/
    └── ip-reservations.yaml       # Content template for generation

tests/
└── test-backstage-ip-reservations.sh  # Comprehensive test suite

live/{environment}/configs/
└── ip-reservations.yaml          # Target configuration file
```

## Integration

### With Existing DNS Records

IP reservations are independent of DNS records but can work together:

1. **Reserve IP first**: Use IP reservation template
2. **Create DNS later**: Use DNS record template with the reserved IP

### With Host Records

If you need both IP and DNS together, use `host-records.yaml` instead of separate reservations.

### With Network Planning

Coordinate with network team for:
- Available IP ranges
- Network CIDR allocation
- VLAN assignments
- Security zone placement

## Troubleshooting

### Common Issues

1. **IP Already Reserved**
   - Check existing reservations: `grep "10.1.100.50" live/*/configs/ip-reservations.yaml`
   - Use `next_available` type for auto-assignment

2. **Invalid MAC Address Format**
   - Use format: `00:11:22:33:44:55` or `00-11-22-33-44-55`
   - Check device MAC address carefully

3. **Network Not Found**
   - Verify network exists in Infoblox
   - Check network CIDR format: `10.1.100.0/24`

4. **Permission Issues**
   - Ensure Backstage entity follows naming convention
   - Verify owner has appropriate permissions

### Testing

The template includes comprehensive testing:

- **Template validation**: YAML syntax and structure
- **Parameter validation**: Required fields and patterns
- **Sample generation**: All 8 reservation types
- **Integration testing**: Compatibility with existing structure
- **Unique ID testing**: Ensures no collisions

## Security Considerations

- **MAC Address Privacy**: MAC addresses are sensitive device identifiers
- **IP Range Planning**: Coordinate with security team for appropriate ranges
- **Access Control**: Use Backstage RBAC to control template access
- **Audit Trail**: All reservations are tracked with creation metadata

## Support

For issues with the IP reservation template:

1. Run tests: `make test-backstage-ip`
2. Check logs in test output directory
3. Validate existing configuration: `make validate ENV={env}`
4. Contact platform team for template issues
5. Contact network team for IP planning guidance
