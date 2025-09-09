# IP Address Management Guide for Infoblox

This guide explains the different ways to manage IP addresses in Infoblox and when to use each approach.

## IP Address Management Methods

### 1. **A Records** (`a-records.yaml`)
**When to use:** When you need DNS resolution AND you know the specific IP address.
```yaml
# Example: A record with specific IP
web_server:
  fqdn: "web01.dev.company.com"
  ip_addr: "10.1.0.10"  # Specific IP address
  view: "default"
  ttl: 3600
```
**Result:** Creates DNS record AND reserves the IP address.

### 2. **Host Records** (`host-records.yaml`)
**When to use:** When you need DNS resolution but want Infoblox to assign an available IP.
```yaml
# Example: Host record with automatic IP allocation
dynamic_server:
  fqdn: "app01.dev.company.com"
  network: "10.1.0.0/24"        # Infoblox picks available IP from this network
  allocate_ip: true
  view: "default"
```
**Result:** Creates DNS record AND automatically allocates/reserves an IP.

### 3. **IP Reservations** (`ip-reservations.yaml`)
**When to use:** When you need to reserve IP addresses WITHOUT DNS records.

#### 3a. Fixed Address (with MAC address)
```yaml
# For devices where you know the MAC address
server_reservation:
  ip_address: "10.1.0.50"
  mac_address: "aa:bb:cc:dd:ee:01"
  comment: "Reserved for server-01"
```
**Result:** Reserves IP for specific device, no DNS record.

#### 3b. Static IP Reservation (without MAC)
```yaml
# Reserve IP for future use
future_server:
  ip_address: "10.1.0.100"
  reservation_type: "static_ip"
  comment: "Reserved for future database server"
```
**Result:** Prevents IP from being allocated to other devices.

#### 3c. IP Range Reservation
```yaml
# Reserve a block of IPs
server_pool:
  network: "10.1.0.0/24"
  start_ip: "10.1.0.200"
  end_ip: "10.1.0.220"
  reservation_type: "static_pool"
```
**Result:** Reserves entire IP range for manual allocation.

## Decision Matrix

| Scenario | File to Use | Method | DNS Record Created? |
|----------|-------------|--------|---------------------|
| **Server with known IP and needs DNS** | `a-records.yaml` | A Record | ✅ Yes |
| **Server needs DNS, any available IP** | `host-records.yaml` | Host Record | ✅ Yes |
| **Device with MAC, needs same IP** | `ip-reservations.yaml` | Fixed Address | ❌ No |
| **Reserve IP for future server** | `ip-reservations.yaml` | Static Reservation | ❌ No |
| **Reserve IP block for team** | `ip-reservations.yaml` | Range Reservation | ❌ No |
| **Load balancer VIP (no DNS needed)** | `ip-reservations.yaml` | VIP Reservation | ❌ No |
| **DHCP client needs consistent IP** | `ip-reservations.yaml` | DHCP Reservation | ❌ No |

## Common Use Cases

### Web Server Setup
```yaml
# Option 1: Known IP + DNS (a-records.yaml)
web01:
  fqdn: "web01.dev.company.com"
  ip_addr: "10.1.0.10"

# Option 2: Auto IP + DNS (host-records.yaml)  
web02:
  fqdn: "web02.dev.company.com"
  network: "10.1.0.0/24"
  allocate_ip: true
```

### Database Server (Private, No DNS)
```yaml
# ip-reservations.yaml
db_server:
  ip_address: "10.1.0.200"
  mac_address: "aa:bb:cc:dd:ee:01"  # If known
  comment: "Database server - no public DNS"
```

### Load Balancer VIP
```yaml
# ip-reservations.yaml
lb_vip:
  ip_address: "10.1.0.250"
  reservation_type: "vip"
  comment: "Load balancer virtual IP"
```

### Development Team IP Pool
```yaml
# ip-reservations.yaml
dev_team_pool:
  network: "10.1.0.0/24"
  start_ip: "10.1.0.100" 
  end_ip: "10.1.0.150"
  reservation_type: "static_pool"
  comment: "Reserved for dev team manual allocation"
```

## Backstage Integration Examples

When using Backstage self-service, users typically need:

### For Applications (with DNS)
```yaml
# Generated in host-records.yaml
backstage_app:
  fqdn: "my-app.dev.company.com"
  network: "10.1.0.0/24"
  allocate_ip: true
  backstage_id: "my-app-dev-20250910120000"
  entity_name: "my-app"
```

### For Infrastructure (no DNS)
```yaml
# Generated in ip-reservations.yaml  
backstage_infra:
  network: "10.1.0.0/24"
  allocate_method: "next_available"
  backstage_id: "my-infra-dev-20250910120000"
  entity_name: "my-infra"
  comment: "Infrastructure component IP"
```

## File Organization

```
live/dev/configs/
├── networks.yaml          # Network definitions (subnets, VLANs)
├── a-records.yaml          # DNS A records with specific IPs
├── host-records.yaml       # DNS records with auto IP allocation
├── ip-reservations.yaml    # IP reservations without DNS
├── cname-records.yaml      # DNS aliases
└── dns-zones.yaml          # DNS zone configurations
```

## Best Practices

1. **Use Host Records** for most servers that need DNS
2. **Use A Records** only when you must specify the exact IP
3. **Use IP Reservations** for infrastructure that doesn't need DNS
4. **Always add comments** explaining the purpose
5. **Use EA tags** for tracking and organization
6. **Reserve IP ranges** for different purposes (servers, DHCP, etc.)

## Cleanup and Management

```bash
# List all IP allocations
make backstage-list ENV=dev

# Remove specific allocation
make backstage-cleanup-id ENV=dev ID=my-app-dev-20250910120000

# Preview what would be removed
make backstage-preview-entity ENV=dev ENTITY=my-app
```
