#!/bin/bash

# Terragrunt Deployment Script for Infoblox
# Usage: ./terragrunt-deploy.sh <environment> [plan|apply|destroy]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LIVE_DIR="$PROJECT_ROOT/live"

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
    echo "  all      - All environments (plan only)"
    echo ""
    echo "Actions:"
    echo "  plan     - Show what would be changed (default)"
    echo "  apply    - Apply the changes"
    echo "  destroy  - Destroy all resources"
    echo "  output   - Show outputs"
    echo "  graph    - Generate dependency graph"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan"
    echo "  $0 staging apply"
    echo "  $0 all plan"
    echo "  $0 prod destroy"
}

validate_environment() {
    local env=$1
    if [[ "$env" != "all" && ! -d "$LIVE_DIR/$env" ]]; then
        log_error "Environment '$env' not found!"
        log_info "Available environments: $(ls "$LIVE_DIR" | tr '\n' ' ')"
        exit 1
    fi
}

check_prerequisites() {
    # Check if terragrunt is installed
    if ! command -v terragrunt &> /dev/null; then
        log_error "Terragrunt is not installed!"
        log_info "Install it from: https://terragrunt.gruntwork.io/docs/getting-started/install/"
        exit 1
    fi

    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed!"
        log_info "Install it from: https://www.terraform.io/downloads"
        exit 1
    fi

    # Check for required environment variables
    if [[ -z "${TG_BUCKET_NAME:-}" ]]; then
        log_warning "TG_BUCKET_NAME environment variable not set"
        log_info "Set it with: export TG_BUCKET_NAME=your-terraform-state-bucket"
    fi
}

setup_credentials() {
    local env_dir="$LIVE_DIR/$environment"
    
    # Check if terragrunt.hcl exists
    if [[ ! -f "$env_dir/terragrunt.hcl" ]]; then
        log_error "terragrunt.hcl not found in $env_dir"
        exit 1
    fi
    
    # Check for .terragrunt-cache and clean if needed
    if [[ -d "$env_dir/.terragrunt-cache" ]]; then
        log_info "Cleaning terragrunt cache..."
        rm -rf "$env_dir/.terragrunt-cache"
    fi
}

plan_environment() {
    local env=$1
    local env_dir="$LIVE_DIR/$env"
    
    log_info "Planning $env environment with Terragrunt..."
    cd "$env_dir"
    
    terragrunt plan -out="tfplan-$env"
    
    if [[ $? -eq 0 ]]; then
        log_success "Terragrunt plan for $env completed successfully"
    else
        log_error "Terragrunt plan for $env failed"
        return 1
    fi
}

apply_environment() {
    local env=$1
    local env_dir="$LIVE_DIR/$env"
    
    log_info "Applying $env environment with Terragrunt..."
    cd "$env_dir"
    
    # Production safety check
    if [[ "$env" == "prod" ]]; then
        log_warning "🚨 You are about to apply changes to PRODUCTION! 🚨"
        read -p "Type 'PRODUCTION' to confirm: " -r
        if [[ $REPLY != "PRODUCTION" ]]; then
            log_info "Production apply cancelled"
            return 0
        fi
    fi
    
    # Check if plan file exists
    if [[ -f "tfplan-$env" ]]; then
        terragrunt apply "tfplan-$env"
    else
        log_warning "No plan file found, running apply with auto-approve"
        read -p "Continue with auto-approve? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terragrunt apply --terragrunt-non-interactive
        else
            log_info "Apply cancelled"
            return 0
        fi
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "Terragrunt apply for $env completed successfully"
        # Clean up plan file
        [[ -f "tfplan-$env" ]] && rm "tfplan-$env"
    else
        log_error "Terragrunt apply for $env failed"
        return 1
    fi
}

destroy_environment() {
    local env=$1
    local env_dir="$LIVE_DIR/$env"
    
    log_warning "This will DESTROY all Infoblox resources in the $env environment!"
    
    if [[ "$env" == "prod" ]]; then
        log_error "🚨 PRODUCTION DESTROY REQUESTED! 🚨"
        read -p "Type 'DESTROY-PRODUCTION-NOW' to confirm: " -r
        if [[ $REPLY != "DESTROY-PRODUCTION-NOW" ]]; then
            log_info "Production destroy cancelled"
            return 0
        fi
    else
        read -p "Are you absolutely sure? Type 'yes' to confirm: " -r
        if [[ $REPLY != "yes" ]]; then
            log_info "Destroy cancelled"
            return 0
        fi
    fi
    
    cd "$env_dir"
    terragrunt destroy --terragrunt-non-interactive
    
    if [[ $? -eq 0 ]]; then
        log_success "Terragrunt destroy for $env completed successfully"
    else
        log_error "Terragrunt destroy for $env failed"
        return 1
    fi
}

show_outputs() {
    local env=$1
    local env_dir="$LIVE_DIR/$env"
    
    log_info "Showing outputs for $env environment..."
    cd "$env_dir"
    terragrunt output
}

generate_graph() {
    log_info "Generating dependency graph..."
    cd "$LIVE_DIR"
    terragrunt graph-dependencies | dot -Tpng > ../infoblox-dependencies.png
    log_success "Graph saved as infoblox-dependencies.png"
}

plan_all_environments() {
    log_info "Planning all environments..."
    cd "$LIVE_DIR"
    terragrunt run-all plan --terragrunt-non-interactive
}

# Main script
if [[ $# -lt 1 ]]; then
    show_usage
    exit 1
fi

environment=$1
action=${2:-plan}

# Check prerequisites
check_prerequisites

# Handle special cases
case $environment in
    all)
        if [[ "$action" == "plan" ]]; then
            plan_all_environments
            exit 0
        elif [[ "$action" == "graph" ]]; then
            generate_graph
            exit 0
        else
            log_error "Only 'plan' and 'graph' actions are supported for 'all' environments"
            exit 1
        fi
        ;;
    *)
        validate_environment "$environment"
        setup_credentials
        ;;
esac

# Execute action
case $action in
    plan)
        plan_environment "$environment"
        ;;
    apply)
        apply_environment "$environment"
        ;;
    destroy)
        destroy_environment "$environment"
        ;;
    output)
        show_outputs "$environment"
        ;;
    graph)
        generate_graph
        ;;
    *)
        log_error "Unknown action: $action"
        show_usage
        exit 1
        ;;
esac

log_success "Terragrunt operation completed successfully!"
