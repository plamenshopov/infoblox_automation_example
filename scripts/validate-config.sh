#!/bin/bash

# Configuration Validation Script for Infoblox
# Usage: ./validate-config.sh <environment>

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

validate_yaml_file() {
    local file=$1
    local name=$2
    
    if [[ -f "$file" ]]; then
        # Check if the file is valid YAML
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            log_success "$name: Valid YAML format"
            return 0
        else
            log_error "$name: Invalid YAML format"
            return 1
        fi
    else
        log_warning "$name: File not found ($file)"
        return 1
    fi
}

validate_ip_addresses() {
    local file=$1
    local errors=0
    
    if [[ -f "$file" ]]; then
        # Extract IP addresses and validate them
        local ips=$(python3 -c "
import yaml, re
try:
    with open('$file') as f:
        data = yaml.safe_load(f)
    if data:
        for key, value in data.items():
            if isinstance(value, dict) and 'ip_addr' in value:
                print(value['ip_addr'])
except:
    pass
")
        
        for ip in $ips; do
            if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                # Validate each octet
                IFS='.' read -ra ADDR <<< "$ip"
                valid=true
                for octet in "${ADDR[@]}"; do
                    if [[ $octet -gt 255 || $octet -lt 0 ]]; then
                        valid=false
                        break
                    fi
                done
                
                if $valid; then
                    log_success "IP address $ip is valid"
                else
                    log_error "IP address $ip is invalid"
                    ((errors++))
                fi
            else
                log_error "IP address $ip has invalid format"
                ((errors++))
            fi
        done
    fi
    
    return $errors
}

validate_fqdns() {
    local file=$1
    local errors=0
    
    if [[ -f "$file" ]]; then
        # Extract FQDNs and validate them
        local fqdns=$(python3 -c "
import yaml, re
try:
    with open('$file') as f:
        data = yaml.safe_load(f)
    if data:
        for key, value in data.items():
            if isinstance(value, dict):
                if 'fqdn' in value:
                    print(value['fqdn'])
                elif 'alias' in value:
                    print(value['alias'])
                elif 'zone' in value:
                    print(value['zone'])
except:
    pass
")
        
        for fqdn in $fqdns; do
            # Basic FQDN validation
            if [[ $fqdn =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
                log_success "FQDN $fqdn is valid"
            else
                log_error "FQDN $fqdn is invalid"
                ((errors++))
            fi
        done
    fi
    
    return $errors
}

validate_networks() {
    local file=$1
    local errors=0
    
    if [[ -f "$file" ]]; then
        # Extract network CIDRs and validate them
        local networks=$(python3 -c "
import yaml, re
try:
    with open('$file') as f:
        data = yaml.safe_load(f)
    if data:
        for key, value in data.items():
            if isinstance(value, dict) and 'network' in value:
                print(value['network'])
except:
    pass
")
        
        for network in $networks; do
            # Basic CIDR validation
            if [[ $network =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
                log_success "Network $network has valid format"
            else
                log_error "Network $network has invalid CIDR format"
                ((errors++))
            fi
        done
    fi
    
    return $errors
}

check_terraform_files() {
    local env_dir=$1
    local errors=0
    
    # Check for required Terraform files
    if [[ ! -f "$env_dir/main.tf" ]]; then
        log_error "main.tf not found in $env_dir"
        ((errors++))
    else
        log_success "main.tf found"
    fi
    
    if [[ ! -f "$env_dir/variables.tf" ]]; then
        log_error "variables.tf not found in $env_dir"
        ((errors++))
    else
        log_success "variables.tf found"
    fi
    
    if [[ ! -f "$env_dir/terraform.tfvars" ]]; then
        log_warning "terraform.tfvars not found in $env_dir"
        if [[ -f "$env_dir/terraform.tfvars.example" ]]; then
            log_info "terraform.tfvars.example found - copy and configure it"
        fi
        ((errors++))
    else
        log_success "terraform.tfvars found"
    fi
    
    return $errors
}

main() {
    local environment=$1
    local total_errors=0
    
    if [[ -z "$environment" ]]; then
        echo "Usage: $0 <environment>"
        echo "Available environments: $(ls "$ENVIRONMENTS_DIR" 2>/dev/null | tr '\n' ' ')"
        exit 1
    fi
    
    local env_dir="$ENVIRONMENTS_DIR/$environment"
    
    if [[ ! -d "$env_dir" ]]; then
        log_error "Environment '$environment' not found!"
        exit 1
    fi
    
    log_info "Validating configuration for environment: $environment"
    echo "=================================================="
    
    # Check Terraform files
    log_info "Checking Terraform files..."
    check_terraform_files "$env_dir"
    ((total_errors += $?))
    
    # Check configuration files
    local configs_dir="$env_dir/configs"
    
    if [[ -d "$configs_dir" ]]; then
        log_info "Validating YAML configuration files..."
        
        # Validate YAML syntax
        validate_yaml_file "$configs_dir/networks.yaml" "Networks config"
        ((total_errors += $?))
        
        validate_yaml_file "$configs_dir/dns-zones.yaml" "DNS zones config"
        ((total_errors += $?))
        
        validate_yaml_file "$configs_dir/a-records.yaml" "A records config"
        ((total_errors += $?))
        
        validate_yaml_file "$configs_dir/cname-records.yaml" "CNAME records config"
        ((total_errors += $?))
        
        validate_yaml_file "$configs_dir/host-records.yaml" "Host records config"
        ((total_errors += $?))
        
        # Validate content
        log_info "Validating IP addresses..."
        validate_ip_addresses "$configs_dir/a-records.yaml"
        ((total_errors += $?))
        
        validate_ip_addresses "$configs_dir/host-records.yaml"
        ((total_errors += $?))
        
        log_info "Validating FQDNs..."
        validate_fqdns "$configs_dir/dns-zones.yaml"
        ((total_errors += $?))
        
        validate_fqdns "$configs_dir/a-records.yaml"
        ((total_errors += $?))
        
        validate_fqdns "$configs_dir/cname-records.yaml"
        ((total_errors += $?))
        
        validate_fqdns "$configs_dir/host-records.yaml"
        ((total_errors += $?))
        
        log_info "Validating networks..."
        validate_networks "$configs_dir/networks.yaml"
        ((total_errors += $?))
    else
        log_error "Configs directory not found: $configs_dir"
        ((total_errors++))
    fi
    
    echo "=================================================="
    if [[ $total_errors -eq 0 ]]; then
        log_success "All validations passed! Configuration is ready for deployment."
        exit 0
    else
        log_error "Found $total_errors error(s). Please fix them before deploying."
        exit 1
    fi
}

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is required for YAML validation"
    exit 1
fi

# Check if PyYAML is available
if ! python3 -c "import yaml" 2>/dev/null; then
    log_error "PyYAML is required. Install it with: pip3 install PyYAML"
    exit 1
fi

main "$@"
