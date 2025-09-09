#!/bin/bash
#
# Common Functions for Infoblox Automation Scripts
# Shared utilities for validation, consistency checks, and common operations
#

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Environment validation
validate_environment_exists() {
    local env="$1"
    if [[ ! -d "live/$env" ]]; then
        log_error "Environment '$env' not found in live/ directory"
        return 1
    fi
    return 0
}

# Tool availability checks
check_tool_available() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

validate_required_tools() {
    local tools=("$@")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! check_tool_available "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    return 0
}

# State validation functions
validate_terragrunt_state() {
    local env="$1"
    local original_dir=$(pwd)
    
    if ! check_tool_available "terragrunt"; then
        log_warning "Terragrunt not available - skipping Terragrunt validation"
        return 0
    fi
    
    cd "live/$env" || return 1
    
    log_info "Validating Terragrunt configuration..."
    if terragrunt validate --terragrunt-non-interactive >/dev/null 2>&1; then
        log_success "Terragrunt configuration valid"
    else
        log_warning "Terragrunt validation issues detected"
    fi
    
    log_info "Checking Terragrunt state accessibility..."
    if terragrunt state list --terragrunt-non-interactive >/dev/null 2>&1; then
        log_success "Terragrunt state accessible"
    else
        log_warning "Terragrunt state not initialized or accessible"
    fi
    
    cd "$original_dir"
    return 0
}

validate_terraform_syntax() {
    local env="$1"
    local original_dir=$(pwd)
    
    if ! check_tool_available "terraform"; then
        log_warning "Terraform not available - skipping Terraform validation"
        return 0
    fi
    
    cd "live/$env" || return 1
    
    if [[ -f "main.tf" ]] || [[ -f "terragrunt.hcl" ]]; then
        log_info "Checking Terraform syntax and formatting..."
        if terraform fmt -check=true >/dev/null 2>&1; then
            log_success "Terraform formatting correct"
        else
            log_warning "Terraform formatting issues detected"
        fi
        
        # Try to validate if there are .tf files
        if ls *.tf >/dev/null 2>&1; then
            if terraform validate >/dev/null 2>&1; then
                log_success "Terraform configuration valid"
            else
                log_warning "Terraform validation issues detected"
            fi
        fi
    fi
    
    cd "$original_dir"
    return 0
}

# Configuration validation
validate_yaml_files() {
    local config_dir="$1"
    
    if ! check_tool_available "python3"; then
        log_warning "Python3 not available - skipping YAML validation"
        return 0
    fi
    
    if ! python3 -c "import yaml" 2>/dev/null; then
        log_warning "PyYAML not installed - skipping YAML validation"
        return 0
    fi
    
    if [[ ! -d "$config_dir" ]]; then
        log_warning "Config directory '$config_dir' not found"
        return 0
    fi
    
    log_info "Validating YAML configuration files..."
    local yaml_files=("$config_dir"/*.yaml)
    local invalid_files=()
    
    for yaml_file in "${yaml_files[@]}"; do
        if [[ -f "$yaml_file" ]]; then
            if ! python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
                invalid_files+=("$yaml_file")
            fi
        fi
    done
    
    if [[ ${#invalid_files[@]} -gt 0 ]]; then
        log_error "Invalid YAML files found: ${invalid_files[*]}"
        return 1
    else
        log_success "All YAML files are valid"
        return 0
    fi
}

# Backup functions
create_backup() {
    local env="$1"
    local backup_dir="backups"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="${backup_dir}/backstage-configs-${env}-${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    log_info "Creating backup of $env configuration..."
    if tar -czf "$backup_file" "live/$env/configs" 2>/dev/null; then
        log_success "Backup created: $backup_file"
        echo "$backup_file"
        return 0
    else
        log_error "Failed to create backup"
        return 1
    fi
}

# Resource management utilities
list_backstage_resources_from_configs() {
    local env="$1"
    local config_dir="live/$env/configs"
    
    if ! validate_required_tools "python3"; then
        return 1
    fi
    
    python3 scripts/manage-backstage-resources.py \
        --config-path "$config_dir" \
        list 2>/dev/null || true
}

find_resources_by_entity() {
    local env="$1"
    local entity="$2"
    local config_dir="live/$env/configs"
    
    if ! validate_required_tools "python3"; then
        return 1
    fi
    
    python3 scripts/manage-backstage-resources.py \
        --config-path "$config_dir" \
        find "$entity" 2>/dev/null || true
}

# Comprehensive environment validation
validate_environment_consistency() {
    local env="$1"
    
    log_info "Running comprehensive validation for $env environment..."
    
    # Check environment exists
    if ! validate_environment_exists "$env"; then
        return 1
    fi
    
    # Validate YAML files
    validate_yaml_files "live/$env/configs"
    
    # Validate Terragrunt if available
    validate_terragrunt_state "$env"
    
    # Validate Terraform if available
    validate_terraform_syntax "$env"
    
    log_success "Environment validation completed for $env"
    return 0
}

# Makefile integration helpers
run_makefile_target() {
    local target="$1"
    shift
    local args="$@"
    
    if ! check_tool_available "make"; then
        log_error "Make not available"
        return 1
    fi
    
    log_info "Running Makefile target: $target $args"
    if make "$target" $args; then
        log_success "Makefile target completed successfully"
        return 0
    else
        log_error "Makefile target failed"
        return 1
    fi
}

# Test integration helpers
test_makefile_target() {
    local target="$1"
    shift
    local args="$@"
    
    log_info "Testing Makefile target: $target $args"
    
    # Capture output and return code
    local output
    local return_code
    
    output=$(make "$target" $args 2>&1) || return_code=$?
    
    if [[ $return_code -eq 0 ]]; then
        log_success "Makefile target test passed: $target"
        return 0
    else
        log_error "Makefile target test failed: $target"
        echo "$output"
        return 1
    fi
}

# File operation helpers
safe_file_operation() {
    local operation="$1"
    local file="$2"
    local backup_file="${file}.backup.$(date +%Y%m%d-%H%M%S)"
    
    case "$operation" in
        "backup")
            if [[ -f "$file" ]]; then
                cp "$file" "$backup_file"
                log_success "Backup created: $backup_file"
                return 0
            else
                log_warning "File not found for backup: $file"
                return 1
            fi
            ;;
        "restore")
            if [[ -f "$backup_file" ]]; then
                cp "$backup_file" "$file"
                log_success "File restored: $file"
                return 0
            else
                log_error "Backup file not found: $backup_file"
                return 1
            fi
            ;;
        *)
            log_error "Unknown operation: $operation"
            return 1
            ;;
    esac
}
