#!/bin/bash
#
# Comprehensive Test Suite for Infoblox Automation
# Tests Makefile targets, script functions, and tool consistency
#

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Source common functions
source "${PROJECT_ROOT}/scripts/common-functions.sh"

# Test configuration
TEST_ENV="dev"
TEST_ENTITY="test-app"
TEST_ID="test-app-${TEST_ENV}-$(date +%Y%m%d%H%M%S)"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
FAILED_TESTS=()

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    log_info "Running test: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        log_success "Test passed: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test failed: $test_name"
        FAILED_TESTS+=("$test_name")
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    local expected_output="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    log_info "Running test with output check: $test_name"
    
    local output
    output=$(eval "$test_command" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && [[ "$output" == *"$expected_output"* ]]; then
        log_success "Test passed: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test failed: $test_name"
        echo "Expected: $expected_output"
        echo "Got: $output"
        echo "Exit code: $exit_code"
        FAILED_TESTS+=("$test_name")
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_tools_availability() {
    log_info "=== Testing Tool Availability ==="
    
    run_test "Python3 available" "command -v python3"
    run_test "PyYAML available" "python3 -c 'import yaml'"
    run_test "Make available" "command -v make"
    
    # Optional tools
    if command -v terragrunt >/dev/null 2>&1; then
        run_test "Terragrunt available" "command -v terragrunt"
        run_test "Terragrunt version" "terragrunt --version | grep -q 'terragrunt version'"
    else
        log_warning "Terragrunt not available - skipping Terragrunt tests"
    fi
    
    if command -v terraform >/dev/null 2>&1; then
        run_test "Terraform available" "command -v terraform"
        run_test "Terraform version" "terraform --version | grep -q 'Terraform'"
    else
        log_warning "Terraform not available - skipping Terraform tests"
    fi
}

test_directory_structure() {
    log_info "=== Testing Directory Structure ==="
    
    run_test "Project root exists" "test -d ."
    run_test "Live directory exists" "test -d live"
    run_test "Modules directory exists" "test -d modules"
    run_test "Scripts directory exists" "test -d scripts"
    run_test "Docs directory exists" "test -d docs"
    
    # Test environment directories
    for env in dev staging prod; do
        run_test "Environment $env exists" "test -d live/$env"
        run_test "Config directory for $env exists" "test -d live/$env/configs"
    done
}

test_required_files() {
    log_info "=== Testing Required Files ==="
    
    local required_files=(
        "Makefile"
        "README.md"
        "scripts/terragrunt-deploy.sh"
        "scripts/validate-config.sh"
        "scripts/backstage-cleanup.sh"
        "scripts/manage-backstage-resources.py"
        "scripts/common-functions.sh"
        "docs/CLEANUP_GUIDE.md"
    )
    
    for file in "${required_files[@]}"; do
        run_test "File exists: $file" "test -f $file"
    done
}

test_script_permissions() {
    log_info "=== Testing Script Permissions ==="
    
    local executable_scripts=(
        "scripts/terragrunt-deploy.sh"
        "scripts/validate-config.sh"
        "scripts/backstage-cleanup.sh"
        "test-setup.sh"
    )
    
    for script in "${executable_scripts[@]}"; do
        run_test "Script executable: $script" "test -x $script"
    done
}

test_yaml_configuration() {
    log_info "=== Testing YAML Configuration ==="
    
    for env in dev staging prod; do
        local config_dir="live/$env/configs"
        if [[ -d "$config_dir" ]]; then
            for yaml_file in "$config_dir"/*.yaml; do
                if [[ -f "$yaml_file" ]]; then
                    local filename=$(basename "$yaml_file")
                    run_test "YAML valid: $env/$filename" "python3 -c \"import yaml; yaml.safe_load(open('$yaml_file'))\""
                fi
            done
        fi
    done
}

test_makefile_help() {
    log_info "=== Testing Makefile Help ==="
    
    run_test_with_output "Makefile help works" "make help" "Available targets"
}

test_makefile_targets() {
    log_info "=== Testing Makefile Targets ==="
    
    # Test help and validation targets (safe to run)
    run_test "Makefile help target" "make help"
    
    # Test parameter validation
    run_test "Makefile ENV validation" "! make tg-plan 2>&1 | grep -q 'Error: ENV parameter required'"
    run_test "Backstage cleanup ID validation" "! make backstage-cleanup-id ENV=$TEST_ENV 2>&1 | grep -q 'Error: ID parameter required'"
    run_test "Backstage cleanup entity validation" "! make backstage-cleanup-entity ENV=$TEST_ENV 2>&1 | grep -q 'Error: ENTITY parameter required'"
    
    # Test backstage list (safe)
    if command -v python3 >/dev/null 2>&1; then
        run_test "Backstage list target" "make backstage-list ENV=$TEST_ENV"
    fi
}

test_cleanup_script_functions() {
    log_info "=== Testing Cleanup Script Functions ==="
    
    # Test script help
    run_test_with_output "Cleanup script help" "./scripts/backstage-cleanup.sh" "Usage:"
    
    # Test list function (safe)
    run_test "Cleanup script list function" "./scripts/backstage-cleanup.sh list-backstage $TEST_ENV"
    
    # Test validation function
    run_test "Cleanup script validate-state function" "./scripts/backstage-cleanup.sh validate-state $TEST_ENV"
    
    # Test invalid environment
    run_test "Cleanup script invalid env handling" "! ./scripts/backstage-cleanup.sh list-backstage invalid-env"
}

test_common_functions() {
    log_info "=== Testing Common Functions ==="
    
    # Source and test common functions
    source "scripts/common-functions.sh"
    
    run_test "Environment validation function" "validate_environment_exists $TEST_ENV"
    run_test "Invalid environment detection" "! validate_environment_exists invalid-env"
    run_test "Tool availability check" "check_tool_available python3"
    run_test "Missing tool detection" "! check_tool_available nonexistent-tool"
    run_test "YAML validation function" "validate_yaml_files live/$TEST_ENV/configs"
}

test_python_scripts() {
    log_info "=== Testing Python Scripts ==="
    
    # Test manage-backstage-resources.py
    local config_path="live/$TEST_ENV/configs"
    
    run_test "Python script list function" "python3 scripts/manage-backstage-resources.py --config-path $config_path list"
    run_test "Python script validate function" "python3 scripts/manage-backstage-resources.py validate '$TEST_ID'"
    
    # Test merge script if it exists
    if [[ -f "scripts/merge-backstage-config.py" ]]; then
        run_test "Python merge script help" "python3 scripts/merge-backstage-config.py --help"
    fi
}

test_terragrunt_integration() {
    log_info "=== Testing Terragrunt Integration ==="
    
    if ! command -v terragrunt >/dev/null 2>&1; then
        log_warning "Terragrunt not available - skipping Terragrunt integration tests"
        return 0
    fi
    
    # Test Terragrunt configuration files exist and have basic structure
    for env in dev staging prod; do
        run_test "Terragrunt config exists ($env)" "test -f live/$env/terragrunt.hcl"
        run_test "Terragrunt config structure ($env)" "grep -q 'terraform' live/$env/terragrunt.hcl && grep -q 'source' live/$env/terragrunt.hcl"
    done
    
    # Test basic Terragrunt commands without backend initialization
    local original_dir=$(pwd)
    cd "live/$TEST_ENV"
    
    # Only test if we can do a quick validation without backend init
    run_test "Terragrunt help command" "terragrunt --help >/dev/null 2>&1"
    
    cd "$original_dir"
}

test_terraform_integration() {
    log_info "=== Testing Terraform Integration ==="
    
    if ! command -v terraform >/dev/null 2>&1; then
        log_warning "Terraform not available - skipping Terraform integration tests"
        return 0
    fi
    
    local original_dir=$(pwd)
    
    # Test root directory Terraform files if they exist
    if ls *.tf >/dev/null 2>&1; then
        run_test "Root Terraform format check" "terraform fmt -check=true"
    fi
    
    # Test environment-specific Terraform files
    for env in dev staging prod; do
        cd "live/$env"
        
        if ls *.tf >/dev/null 2>&1; then
            run_test "Terraform format check ($env)" "terraform fmt -check=true"
            
            # Only validate if we can initialize
            if terraform init -backend=false >/dev/null 2>&1; then
                run_test "Terraform validation ($env)" "terraform validate"
            fi
        fi
        
        cd "$original_dir"
    done
    
    cd "$original_dir"
}

test_consistency_checks() {
    log_info "=== Testing Consistency Checks ==="
    
    # Test environment consistency using common functions
    source "scripts/common-functions.sh"
    run_test "Environment consistency check" "validate_environment_consistency $TEST_ENV"
    
    # Test that all environments have consistent structure
    for env in dev staging prod; do
        run_test "Environment structure consistency ($env)" "validate_environment_exists $env"
        run_test "Config directory consistency ($env)" "test -d live/$env/configs"
        run_test "Terragrunt config consistency ($env)" "test -f live/$env/terragrunt.hcl"
    done
}

test_error_handling() {
    log_info "=== Testing Error Handling ==="
    
    # Test script error handling
    run_test "Cleanup script invalid action" "! ./scripts/backstage-cleanup.sh invalid-action"
    run_test "Cleanup script missing parameters" "! ./scripts/backstage-cleanup.sh cleanup-id"
    run_test "Makefile invalid target" "! make invalid-target"
    
    # Test Python script error handling
    run_test "Python script invalid config path" "! python3 scripts/manage-backstage-resources.py --config-path /invalid/path list"
}

create_test_summary() {
    echo ""
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Total tests: $TESTS_TOTAL"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
        echo ""
        return 1
    else
        log_success "All tests passed!"
        return 0
    fi
}

# Main test execution
main() {
    echo "🧪 Comprehensive Infoblox Automation Test Suite"
    echo "=============================================="
    echo ""
    
    test_tools_availability
    test_directory_structure
    test_required_files
    test_script_permissions
    test_yaml_configuration
    test_makefile_help
    test_makefile_targets
    test_cleanup_script_functions
    test_common_functions
    test_python_scripts
    test_terragrunt_integration
    test_terraform_integration
    test_consistency_checks
    test_error_handling
    
    create_test_summary
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
