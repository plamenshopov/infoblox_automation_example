#!/bin/bash

# Terraform Deployment Script for Infoblox
# Usage: ./deploy.sh <environment> [plan|apply|destroy]

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

show_usage() {
    echo "Usage: $0 <environment> [action]"
    echo ""
    echo "Environments:"
    echo "  dev      - Development environment"
    echo "  staging  - Staging environment"
    echo "  prod     - Production environment"
    echo ""
    echo "Actions:"
    echo "  plan     - Show what would be changed (default)"
    echo "  apply    - Apply the changes"
    echo "  destroy  - Destroy all resources"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan"
    echo "  $0 staging apply"
    echo "  $0 prod destroy"
}

validate_environment() {
    local env=$1
    if [[ ! -d "$ENVIRONMENTS_DIR/$env" ]]; then
        log_error "Environment '$env' not found!"
        log_info "Available environments: $(ls "$ENVIRONMENTS_DIR" | tr '\n' ' ')"
        exit 1
    fi
}

check_prerequisites() {
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed!"
        exit 1
    fi

    # Check if required files exist
    local env_dir="$ENVIRONMENTS_DIR/$environment"
    if [[ ! -f "$env_dir/terraform.tfvars" ]]; then
        log_warning "terraform.tfvars not found in $env_dir"
        if [[ -f "$env_dir/terraform.tfvars.example" ]]; then
            log_info "Please copy terraform.tfvars.example to terraform.tfvars and configure it"
            log_info "cp $env_dir/terraform.tfvars.example $env_dir/terraform.tfvars"
        fi
        exit 1
    fi
}

init_terraform() {
    local env_dir="$ENVIRONMENTS_DIR/$environment"
    log_info "Initializing Terraform for $environment environment..."
    
    cd "$env_dir"
    terraform init
    
    if [[ $? -eq 0 ]]; then
        log_success "Terraform initialized successfully"
    else
        log_error "Terraform initialization failed"
        exit 1
    fi
}

validate_terraform() {
    log_info "Validating Terraform configuration..."
    terraform validate
    
    if [[ $? -eq 0 ]]; then
        log_success "Terraform configuration is valid"
    else
        log_error "Terraform configuration validation failed"
        exit 1
    fi
}

plan_terraform() {
    log_info "Creating Terraform plan for $environment environment..."
    terraform plan -out="tfplan-$environment"
    
    if [[ $? -eq 0 ]]; then
        log_success "Terraform plan created successfully"
        log_info "Plan saved as: tfplan-$environment"
    else
        log_error "Terraform plan failed"
        exit 1
    fi
}

apply_terraform() {
    log_info "Applying Terraform changes for $environment environment..."
    
    # Check if plan file exists
    if [[ -f "tfplan-$environment" ]]; then
        log_info "Using existing plan file: tfplan-$environment"
        terraform apply "tfplan-$environment"
    else
        log_warning "No plan file found, running apply with auto-approve"
        read -p "Are you sure you want to apply changes without a plan? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform apply -auto-approve
        else
            log_info "Apply cancelled"
            exit 0
        fi
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "Terraform apply completed successfully"
        # Clean up plan file
        [[ -f "tfplan-$environment" ]] && rm "tfplan-$environment"
    else
        log_error "Terraform apply failed"
        exit 1
    fi
}

destroy_terraform() {
    log_warning "This will DESTROY all Infoblox resources in the $environment environment!"
    read -p "Are you absolutely sure? Type 'yes' to confirm: " -r
    echo
    if [[ $REPLY == "yes" ]]; then
        terraform destroy -auto-approve
        if [[ $? -eq 0 ]]; then
            log_success "Terraform destroy completed successfully"
        else
            log_error "Terraform destroy failed"
            exit 1
        fi
    else
        log_info "Destroy cancelled"
        exit 0
    fi
}

# Main script
if [[ $# -lt 1 ]]; then
    show_usage
    exit 1
fi

environment=$1
action=${2:-plan}

# Validate inputs
validate_environment "$environment"

# Check prerequisites
check_prerequisites

# Initialize and validate
init_terraform
validate_terraform

# Execute action
case $action in
    plan)
        plan_terraform
        ;;
    apply)
        apply_terraform
        ;;
    destroy)
        destroy_terraform
        ;;
    *)
        log_error "Unknown action: $action"
        show_usage
        exit 1
        ;;
esac

log_success "Script completed successfully!"
