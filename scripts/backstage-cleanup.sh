#!/bin/bash
#
# Targeted Backstage Resource Cleanup Script
# Safely removes specific Backstage resources without affecting manual ones
#

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Source common functions
source "${PROJECT_ROOT}/scripts/common-functions.sh" || true

usage() {
    echo "Usage: $0 <action> <environment> [identifier]"
    echo ""
    echo "Actions:"
    echo "  list-backstage ENV              - List all Backstage-created resources"
    echo "  list-entity ENV ENTITY          - List resources for specific entity"
    echo "  cleanup-id ENV BACKSTAGE_ID     - Remove specific resource by Backstage ID"
    echo "  cleanup-entity ENV ENTITY       - Remove all resources for entity"
    echo "  preview-id ENV BACKSTAGE_ID     - Preview what would be removed"
    echo "  preview-entity ENV ENTITY       - Preview what would be removed for entity"
    echo "  validate-state ENV              - Validate Terraform/Terragrunt state consistency"
    echo ""
    echo "Examples:"
    echo "  $0 list-backstage dev"
    echo "  $0 cleanup-id dev my-app-dev-20250909120000"
    echo "  $0 cleanup-entity dev my-app"
    echo "  $0 preview-entity dev my-app"
    echo "  $0 validate-state dev"
    exit 1
}

validate_environment() {
    local env="$1"
    if [[ ! -d "live/$env" ]]; then
        echo -e "${RED}Error: Environment '$env' not found in live/ directory${NC}"
        exit 1
    fi
}

# Validate tools are available
validate_tools() {
    local env="$1"
    local required_tools=()
    
    # Always require Python
    required_tools+=("python3")
    
    # Check for Terragrunt if available
    if command -v terragrunt >/dev/null 2>&1; then
        required_tools+=("terragrunt")
        echo -e "${GREEN}✓ Terragrunt available for validation${NC}"
    else
        echo -e "${YELLOW}⚠ Terragrunt not found - skipping state validation${NC}"
    fi
    
    # Check for Terraform if available
    if command -v terraform >/dev/null 2>&1; then
        required_tools+=("terraform")
        echo -e "${GREEN}✓ Terraform available for validation${NC}"
    else
        echo -e "${YELLOW}⚠ Terraform not found - skipping direct validation${NC}"
    fi
    
    for tool in "${required_tools[@]}"; do
        if [[ "$tool" == "terragrunt" ]] || [[ "$tool" == "terraform" ]]; then
            continue  # Already checked above
        fi
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo -e "${RED}Error: Required tool '$tool' not found${NC}"
            exit 1
        fi
    done
}

# Validate state consistency
validate_state_consistency() {
    local env="$1"
    echo -e "${BLUE}🔍 Validating state consistency for $env environment...${NC}"
    
    validate_environment "$env"
    validate_tools "$env"
    
    cd "live/$env"
    
    # Terragrunt validation if available
    if command -v terragrunt >/dev/null 2>&1; then
        echo "  Checking Terragrunt configuration..."
        if terragrunt validate --terragrunt-non-interactive 2>/dev/null; then
            echo -e "${GREEN}  ✓ Terragrunt configuration valid${NC}"
        else
            echo -e "${YELLOW}  ⚠ Terragrunt validation warnings (may be normal)${NC}"
        fi
        
        echo "  Checking Terragrunt state..."
        if terragrunt state list --terragrunt-non-interactive >/dev/null 2>&1; then
            echo -e "${GREEN}  ✓ Terragrunt state accessible${NC}"
        else
            echo -e "${YELLOW}  ⚠ Terragrunt state not initialized or accessible${NC}"
        fi
    fi
    
    # Terraform validation if available and terraform files exist
    if command -v terraform >/dev/null 2>&1 && [[ -f "main.tf" || -f "terragrunt.hcl" ]]; then
        echo "  Checking Terraform syntax..."
        if terraform fmt -check=true 2>/dev/null; then
            echo -e "${GREEN}  ✓ Terraform formatting correct${NC}"
        else
            echo -e "${YELLOW}  ⚠ Terraform formatting issues detected${NC}"
        fi
    fi
    
    cd "$PROJECT_ROOT"
    echo -e "${GREEN}✓ State consistency check completed${NC}"
}

list_backstage_resources() {
    local env="$1"
    validate_environment "$env"
    
    echo -e "${BLUE}📋 Backstage Resources in $env Environment${NC}"
    echo "================================================"
    
    python3 scripts/manage-backstage-resources.py \
        --config-path "live/$env/configs" \
        list --format table
}

list_entity_resources() {
    local env="$1"
    local entity="$2"
    validate_environment "$env"
    
    echo -e "${BLUE}📋 Resources for Entity '$entity' in $env Environment${NC}"
    echo "================================================"
    
    python3 scripts/manage-backstage-resources.py \
        --config-path "live/$env/configs" \
        find "$entity"
}

preview_cleanup_by_id() {
    local env="$1"
    local backstage_id="$2"
    validate_environment "$env"
    
    echo -e "${YELLOW}🔍 Preview: What would be removed for ID '$backstage_id'${NC}"
    echo "================================================"
    
    python3 scripts/manage-backstage-resources.py \
        --config-path "live/$env/configs" \
        cleanup "$backstage_id" --dry-run
}

preview_cleanup_by_entity() {
    local env="$1"
    local entity="$2"
    validate_environment "$env"
    
    echo -e "${YELLOW}🔍 Preview: What would be removed for Entity '$entity'${NC}"
    echo "================================================"
    
    # Get all resources for the entity
    local resources
    resources=$(python3 scripts/manage-backstage-resources.py \
        --config-path "live/$env/configs" \
        find "$entity" --format json | jq -r '.[].backstage_id // empty')
    
    if [[ -z "$resources" ]]; then
        echo -e "${YELLOW}No resources found for entity '$entity'${NC}"
        return 0
    fi
    
    echo "Resources that would be removed:"
    while IFS= read -r resource_id; do
        echo -e "${YELLOW}  - $resource_id${NC}"
        python3 scripts/manage-backstage-resources.py \
            --config-path "live/$env/configs" \
            cleanup "$resource_id" --dry-run --quiet
    done <<< "$resources"
}

cleanup_by_id() {
    local env="$1"
    local backstage_id="$2"
    validate_environment "$env"
    
    echo -e "${BLUE}🧹 Cleaning up Backstage resource: $backstage_id${NC}"
    echo "================================================"
    
    # First show what will be removed
    echo -e "${YELLOW}Preview of changes:${NC}"
    python3 scripts/manage-backstage-resources.py \
        --config-path "live/$env/configs" \
        cleanup "$backstage_id" --dry-run
    
    echo ""
    read -p "Are you sure you want to remove this resource? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Cleanup cancelled${NC}"
        return 0
    fi
    
    # Create backup
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir="backups/cleanup_${backstage_id}_${timestamp}"
    mkdir -p "$backup_dir"
    cp -r "live/$env/configs/"* "$backup_dir/" 2>/dev/null || true
    echo -e "${GREEN}✅ Backup created: $backup_dir${NC}"
    
    # Generate cleanup configuration
    cleanup_config=$(python3 scripts/manage-backstage-resources.py \
        --config-path "live/$env/configs" \
        cleanup "$backstage_id")
    
    # Apply the cleanup
    echo "$cleanup_config" > "/tmp/cleanup_${backstage_id}.yaml"
    
    # Remove from YAML files
    python3 scripts/manage-backstage-resources.py \
        --config-path "live/$env/configs" \
        remove "$backstage_id"
    
    echo -e "${GREEN}✅ Resource $backstage_id removed from configuration${NC}"
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Review changes: git diff live/$env/configs/"
    echo "2. Apply infrastructure changes: cd live/$env && terragrunt plan && terragrunt apply"
    echo "3. If issues occur, restore from backup: cp -r $backup_dir/* live/$env/configs/"
}

cleanup_by_entity() {
    local env="$1"
    local entity="$2"
    validate_environment "$env"
    
    echo -e "${BLUE}🧹 Cleaning up all resources for Entity: $entity${NC}"
    echo "================================================"
    
    # Get all resources for the entity
    local resources
    resources=$(python3 scripts/manage-backstage-resources.py \
        --config-path "live/$env/configs" \
        find "$entity" --format json | jq -r '.[].backstage_id // empty')
    
    if [[ -z "$resources" ]]; then
        echo -e "${YELLOW}No resources found for entity '$entity'${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Found resources for entity '$entity':${NC}"
    while IFS= read -r resource_id; do
        echo -e "${YELLOW}  - $resource_id${NC}"
    done <<< "$resources"
    
    # Show preview
    echo -e "\n${YELLOW}Preview of changes:${NC}"
    preview_cleanup_by_entity "$env" "$entity"
    
    echo ""
    read -p "Are you sure you want to remove ALL resources for entity '$entity'? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Cleanup cancelled${NC}"
        return 0
    fi
    
    # Create backup
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir="backups/cleanup_entity_${entity}_${timestamp}"
    mkdir -p "$backup_dir"
    cp -r "live/$env/configs/"* "$backup_dir/" 2>/dev/null || true
    echo -e "${GREEN}✅ Backup created: $backup_dir${NC}"
    
    # Remove each resource
    while IFS= read -r resource_id; do
        echo -e "${BLUE}Removing resource: $resource_id${NC}"
        python3 scripts/manage-backstage-resources.py \
            --config-path "live/$env/configs" \
            remove "$resource_id"
    done <<< "$resources"
    
    echo -e "${GREEN}✅ All resources for entity '$entity' removed from configuration${NC}"
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Review changes: git diff live/$env/configs/"
    echo "2. Apply infrastructure changes: cd live/$env && terragrunt plan && terragrunt apply"
    echo "3. If issues occur, restore from backup: cp -r $backup_dir/* live/$env/configs/"
}

# Main script logic
case "${1:-}" in
    "list-backstage")
        [[ -z "$2" ]] && usage
        list_backstage_resources "$2"
        ;;
    "list-entity")
        [[ -z "$2" || -z "$3" ]] && usage
        list_entity_resources "$2" "$3"
        ;;
    "preview-id")
        [[ -z "$2" || -z "$3" ]] && usage
        preview_cleanup_by_id "$2" "$3"
        ;;
    "preview-entity")
        [[ -z "$2" || -z "$3" ]] && usage
        preview_cleanup_by_entity "$2" "$3"
        ;;
    "cleanup-id")
        [[ -z "$2" || -z "$3" ]] && usage
        cleanup_by_id "$2" "$3"
        ;;
    "cleanup-entity")
        [[ -z "$2" || -z "$3" ]] && usage
        cleanup_by_entity "$2" "$3"
        ;;
    "validate-state")
        [[ -z "$2" ]] && usage
        validate_state_consistency "$2"
        ;;
    *)
        usage
        ;;
esac
