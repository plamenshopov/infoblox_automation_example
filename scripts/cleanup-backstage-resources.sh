#!/bin/bash
"""
Backstage Resource Cleanup Script
Removes Infoblox resources created by Backstage using Terraform
"""

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
ENVIRONMENT=""
ENTITY_NAME=""
BACKSTAGE_ID=""
DRY_RUN=false
FORCE=false
USE_TERRAGRUNT=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Cleanup Infoblox resources created by Backstage

OPTIONS:
    -e, --environment ENV    Target environment (dev/staging/prod)
    -n, --entity-name NAME   Backstage entity name to cleanup
    -i, --backstage-id ID    Specific Backstage ID to cleanup
    -d, --dry-run           Show what would be removed without executing
    -f, --force             Skip confirmation prompts
    -t, --terragrunt        Use Terragrunt instead of standard Terraform
    -h, --help              Show this help message

EXAMPLES:
    # Remove all resources for an entity in dev environment
    $0 -e dev -n my-app

    # Remove specific resource by Backstage ID
    $0 -e dev -i my-app-dev-20250909120000

    # Dry run to see what would be removed
    $0 -e dev -n my-app --dry-run

    # Use with Terragrunt
    $0 -e dev -n my-app --terragrunt

EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

confirm_action() {
    local message="$1"
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}$message${NC}"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
}

find_backstage_resources() {
    local env="$1"
    local entity="$2"
    local backstage_id="$3"
    
    log_info "Searching for Backstage resources..."
    
    cd "$PROJECT_ROOT/environments/$env" || {
        log_error "Environment directory not found: $env"
        exit 1
    }
    
    local filter_args=""
    if [[ -n "$entity" ]]; then
        filter_args="--entity $entity"
    fi
    
    python3 "$SCRIPT_DIR/manage-backstage-resources.py" list $filter_args --format json > /tmp/backstage_resources.json
    
    if [[ -n "$backstage_id" ]]; then
        # Filter for specific Backstage ID
        jq --arg id "$backstage_id" '.[] | select(.backstage_id == $id)' /tmp/backstage_resources.json > /tmp/filtered_resources.json
    else
        cp /tmp/backstage_resources.json /tmp/filtered_resources.json
    fi
    
    local resource_count=$(jq length /tmp/filtered_resources.json)
    
    if [[ "$resource_count" -eq 0 ]]; then
        log_warn "No Backstage resources found matching criteria"
        exit 0
    fi
    
    log_info "Found $resource_count Backstage resource(s):"
    jq -r '.[] | "  - \(.backstage_id) (\(.record_type)) - \(.resource_name)"' /tmp/filtered_resources.json
}

generate_terraform_targets() {
    log_info "Generating Terraform target list..."
    
    # Convert resource information to Terraform targets
    jq -r '.[] | "\(.source_file):\(.resource_name)"' /tmp/filtered_resources.json | while read -r resource_info; do
        local source_file=$(echo "$resource_info" | cut -d: -f1)
        local resource_name=$(echo "$resource_info" | cut -d: -f2)
        
        case "$source_file" in
            "a-records.yaml")
                echo "module.dns.infoblox_a_record.$resource_name"
                ;;
            "cname-records.yaml")
                echo "module.dns.infoblox_cname_record.$resource_name"
                ;;
            "host-records.yaml")
                echo "module.dns.infoblox_host_record.$resource_name"
                ;;
            "networks.yaml")
                echo "module.ipam.infoblox_network.$resource_name"
                ;;
            "dns-zones.yaml")
                echo "module.dns.infoblox_zone_auth.$resource_name"
                ;;
        esac
    done > /tmp/terraform_targets.txt
}

backup_configurations() {
    local env="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$PROJECT_ROOT/backups/cleanup_$timestamp"
    
    log_info "Creating backup of configurations..."
    mkdir -p "$backup_dir"
    
    # Backup current configurations
    cp "$PROJECT_ROOT/environments/$env/"*.yaml "$backup_dir/" 2>/dev/null || true
    
    # Create cleanup metadata
    jq -n --argjson resources "$(cat /tmp/filtered_resources.json)" \
       --arg timestamp "$timestamp" \
       --arg environment "$env" \
       '{
         cleanup_timestamp: $timestamp,
         environment: $environment,
         resources_removed: $resources,
         backup_location: "'"$backup_dir"'"
       }' > "$backup_dir/cleanup_metadata.json"
    
    log_info "Backup created at: $backup_dir"
}

remove_from_yaml_configs() {
    log_info "Removing resources from YAML configurations..."
    
    jq -r '.[] | "\(.source_file):\(.resource_name)"' /tmp/filtered_resources.json | while read -r resource_info; do
        local source_file=$(echo "$resource_info" | cut -d: -f1)
        local resource_name=$(echo "$resource_info" | cut -d: -f2)
        local config_file="$PROJECT_ROOT/environments/$ENVIRONMENT/$source_file"
        
        if [[ -f "$config_file" ]]; then
            log_info "Removing $resource_name from $source_file"
            
            # Use Python to safely remove the resource from YAML
            python3 -c "
import yaml
import sys

config_file = '$config_file'
resource_name = '$resource_name'

try:
    with open(config_file, 'r') as f:
        data = yaml.safe_load(f) or {}
    
    if resource_name in data:
        del data[resource_name]
        
        with open(config_file, 'w') as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)
        
        print(f'Removed {resource_name} from {config_file}')
    else:
        print(f'Resource {resource_name} not found in {config_file}')
        
except Exception as e:
    print(f'Error updating {config_file}: {e}')
    sys.exit(1)
"
        fi
    done
}

execute_terraform_destroy() {
    local env="$1"
    
    log_info "Executing Terraform destroy for selected resources..."
    
    if [[ "$USE_TERRAGRUNT" == "true" ]]; then
        cd "$PROJECT_ROOT/live/$env"
        
        # Set environment variables for Infoblox
        export TF_VAR_infoblox_username="${INFOBLOX_USERNAME:-}"
        export TF_VAR_infoblox_password="${INFOBLOX_PASSWORD:-}"
        export TF_VAR_infoblox_server="${INFOBLOX_SERVER:-}"
        
        # Initialize if needed
        if [[ ! -d ".terragrunt-cache" ]]; then
            terragrunt init
        fi
        
        # Destroy specific targets
        while read -r target; do
            if [[ -n "$target" ]]; then
                log_info "Destroying: $target"
                if [[ "$DRY_RUN" == "false" ]]; then
                    terragrunt destroy -target="$target" -auto-approve
                else
                    log_info "[DRY RUN] Would destroy: $target"
                fi
            fi
        done < /tmp/terraform_targets.txt
        
    else
        cd "$PROJECT_ROOT/environments/$env"
        
        # Create terraform.tfvars if it doesn't exist
        if [[ ! -f "terraform.tfvars" ]]; then
            cat > terraform.tfvars << EOF
infoblox_username   = "${INFOBLOX_USERNAME:-}"
infoblox_password   = "${INFOBLOX_PASSWORD:-}"
infoblox_server     = "${INFOBLOX_SERVER:-}"
infoblox_ssl_verify = true
EOF
        fi
        
        # Initialize if needed
        if [[ ! -d ".terraform" ]]; then
            terraform init
        fi
        
        # Destroy specific targets
        while read -r target; do
            if [[ -n "$target" ]]; then
                log_info "Destroying: $target"
                if [[ "$DRY_RUN" == "false" ]]; then
                    terraform destroy -target="$target" -auto-approve
                else
                    log_info "[DRY RUN] Would destroy: $target"
                fi
            fi
        done < /tmp/terraform_targets.txt
    fi
}

cleanup_temp_files() {
    rm -f /tmp/backstage_resources.json /tmp/filtered_resources.json /tmp/terraform_targets.txt
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -n|--entity-name)
                ENTITY_NAME="$2"
                shift 2
                ;;
            -i|--backstage-id)
                BACKSTAGE_ID="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -t|--terragrunt)
                USE_TERRAGRUNT=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$ENVIRONMENT" ]]; then
        log_error "Environment is required (-e/--environment)"
        usage
        exit 1
    fi
    
    if [[ -z "$ENTITY_NAME" && -z "$BACKSTAGE_ID" ]]; then
        log_error "Either entity name (-n) or Backstage ID (-i) is required"
        usage
        exit 1
    fi
    
    # Validate environment
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment. Must be: dev, staging, or prod"
        exit 1
    fi
    
    # Check if environment directory exists
    local env_dir
    if [[ "$USE_TERRAGRUNT" == "true" ]]; then
        env_dir="$PROJECT_ROOT/live/$ENVIRONMENT"
    else
        env_dir="$PROJECT_ROOT/environments/$ENVIRONMENT"
    fi
    
    if [[ ! -d "$env_dir" ]]; then
        log_error "Environment directory not found: $env_dir"
        exit 1
    fi
    
    log_info "Starting Backstage resource cleanup..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Entity: ${ENTITY_NAME:-N/A}"
    log_info "Backstage ID: ${BACKSTAGE_ID:-N/A}"
    log_info "Mode: $([ "$DRY_RUN" == "true" ] && echo "DRY RUN" || echo "EXECUTE")"
    log_info "Tool: $([ "$USE_TERRAGRUNT" == "true" ] && echo "Terragrunt" || echo "Terraform")"
    
    # Execute cleanup steps
    find_backstage_resources "$ENVIRONMENT" "$ENTITY_NAME" "$BACKSTAGE_ID"
    generate_terraform_targets
    
    if [[ "$DRY_RUN" == "false" ]]; then
        confirm_action "This will permanently remove the listed resources from Infoblox."
        backup_configurations "$ENVIRONMENT"
    fi
    
    execute_terraform_destroy "$ENVIRONMENT"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        remove_from_yaml_configs
        log_success "Cleanup completed successfully!"
    else
        log_info "Dry run completed. No changes were made."
    fi
    
    cleanup_temp_files
}

# Trap to ensure cleanup on exit
trap cleanup_temp_files EXIT

main "$@"
