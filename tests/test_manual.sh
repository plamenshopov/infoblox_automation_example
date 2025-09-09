#!/bin/bash
#
# Manual Test Script for Backstage Scripts
# Simple bash-based tests to verify functionality
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0

# Project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$SCRIPT_DIR"
FIXTURES_DIR="$TESTS_DIR/fixtures"

log_test() {
    echo -e "${BLUE}🧪 $1${NC}"
}

log_pass() {
    echo -e "${GREEN}  ✅ $1${NC}"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}  ❌ $1${NC}"
    ((FAILED++))
}

log_info() {
    echo -e "${YELLOW}  ℹ️  $1${NC}"
}

# Create temporary test environment
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    ENV_DIR="$TEST_DIR/environments/test-env"
    mkdir -p "$ENV_DIR"
    
    # Copy fixtures if they exist
    if [[ -d "$FIXTURES_DIR" ]]; then
        cp "$FIXTURES_DIR/existing-a-records.yaml" "$ENV_DIR/a-records.yaml" 2>/dev/null || true
        cp "$FIXTURES_DIR/existing-cname-records.yaml" "$ENV_DIR/cname-records.yaml" 2>/dev/null || true
    fi
    
    echo "$TEST_DIR"
}

cleanup_test_env() {
    local test_dir="$1"
    [[ -n "$test_dir" && "$test_dir" != "/" ]] && rm -rf "$test_dir"
}

test_script_exists() {
    log_test "Checking if scripts exist"
    
    if [[ -f "$PROJECT_ROOT/scripts/merge-backstage-config.py" ]]; then
        log_pass "merge-backstage-config.py exists"
    else
        log_fail "merge-backstage-config.py not found"
    fi
    
    if [[ -f "$PROJECT_ROOT/scripts/manage-backstage-resources.py" ]]; then
        log_pass "manage-backstage-resources.py exists"
    else
        log_fail "manage-backstage-resources.py not found"
    fi
    
    if [[ -f "$PROJECT_ROOT/scripts/cleanup-backstage-resources.sh" ]]; then
        log_pass "cleanup-backstage-resources.sh exists"
    else
        log_fail "cleanup-backstage-resources.sh not found"
    fi
}

test_script_permissions() {
    log_test "Checking script permissions"
    
    local scripts=(
        "merge-backstage-config.py"
        "manage-backstage-resources.py" 
        "cleanup-backstage-resources.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -x "$PROJECT_ROOT/scripts/$script" ]]; then
            log_pass "$script is executable"
        else
            log_fail "$script is not executable"
        fi
    done
}

test_python_dependencies() {
    log_test "Checking Python dependencies"
    
    if python3 -c "import yaml" 2>/dev/null; then
        log_pass "PyYAML is available"
    else
        log_fail "PyYAML is not available (pip install PyYAML)"
    fi
    
    if python3 -c "import json" 2>/dev/null; then
        log_pass "JSON module is available"
    else
        log_fail "JSON module is not available"
    fi
}

test_fixtures_valid() {
    log_test "Validating test fixtures"
    
    if [[ ! -d "$FIXTURES_DIR" ]]; then
        log_fail "Fixtures directory not found: $FIXTURES_DIR"
        return
    fi
    
    local fixture_files=(
        "existing-a-records.yaml"
        "existing-cname-records.yaml"
        "new-backstage-a-records.yaml"
        "new-backstage-cname-records.yaml"
        "conflicting-a-records.yaml"
    )
    
    for fixture in "${fixture_files[@]}"; do
        if [[ -f "$FIXTURES_DIR/$fixture" ]]; then
            if python3 -c "import yaml; yaml.safe_load(open('$FIXTURES_DIR/$fixture'))" 2>/dev/null; then
                log_pass "$fixture is valid YAML"
            else
                log_fail "$fixture has invalid YAML syntax"
            fi
        else
            log_fail "$fixture not found"
        fi
    done
}

test_merge_script_help() {
    log_test "Testing merge script help"
    
    cd "$PROJECT_ROOT"
    
    if python3 scripts/merge-backstage-config.py --help >/dev/null 2>&1; then
        log_pass "Merge script shows help"
    else
        log_fail "Merge script help failed"
    fi
}

test_manage_script_help() {
    log_test "Testing manage script help"
    
    cd "$PROJECT_ROOT"
    
    if python3 scripts/manage-backstage-resources.py --help >/dev/null 2>&1; then
        log_pass "Manage script shows help"
    else
        log_fail "Manage script help failed"
    fi
}

test_cleanup_script_help() {
    log_test "Testing cleanup script help"
    
    cd "$PROJECT_ROOT"
    
    if bash scripts/cleanup-backstage-resources.sh --help >/dev/null 2>&1; then
        log_pass "Cleanup script shows help"
    else
        log_fail "Cleanup script help failed"
    fi
}

test_merge_script_basic() {
    log_test "Testing merge script basic functionality"
    
    local test_dir
    test_dir=$(setup_test_env)
    
    cd "$test_dir"
    
    # Create a simple Backstage file
    cat > a-records.yaml << 'EOF'
# Environment: test-env
# Backstage ID: test-app-test-20250909120000

test_merge_resource:
  fqdn: "test.example.com"
  ip_addr: "10.1.1.1"
  view: "default"
  ttl: 3600
  comment: "Test merge resource | Backstage ID: test-app-test-20250909120000"
  ea_tags:
    BackstageId: "test-app-test-20250909120000"
    BackstageEntity: "test-app"
    CreatedBy: "backstage"
    Owner: "test-team"
EOF
    
    # Run merge script
    if python3 "$PROJECT_ROOT/scripts/merge-backstage-config.py" test-env --source-dir . --strategy backstage-wins >/dev/null 2>&1; then
        log_pass "Merge script executed without errors"
        
        # Check if merged file exists
        if [[ -f "environments/test-env/a-records.yaml" ]]; then
            log_pass "Merged file was created"
            
            # Check if resource was merged
            if grep -q "test_merge_resource" "environments/test-env/a-records.yaml"; then
                log_pass "Resource was merged into target file"
            else
                log_fail "Resource was not found in merged file"
            fi
            
            # Check if existing resource was preserved (if fixture exists)
            if grep -q "legacy_web_server" "environments/test-env/a-records.yaml" 2>/dev/null; then
                log_pass "Existing resources were preserved"
            else
                log_info "No existing resources to preserve (fixtures not loaded)"
            fi
        else
            log_fail "Merged file was not created"
        fi
        
        # Check if backup was created
        if find . -name "backups" -type d | head -1 >/dev/null 2>&1; then
            log_pass "Backup directory was created"
        else
            log_fail "Backup directory was not created"
        fi
        
    else
        log_fail "Merge script failed to execute"
    fi
    
    cleanup_test_env "$test_dir"
}

test_manage_script_basic() {
    log_test "Testing manage script basic functionality"
    
    local test_dir
    test_dir=$(setup_test_env)
    
    cd "$test_dir"
    
    # Test with empty directory first
    if python3 "$PROJECT_ROOT/scripts/manage-backstage-resources.py" --config-path environments/test-env list --format json >/dev/null 2>&1; then
        log_pass "Manage script list command works"
    else
        log_fail "Manage script list command failed"
    fi
    
    # Test validate command with valid ID
    if python3 "$PROJECT_ROOT/scripts/manage-backstage-resources.py" validate "test-app-dev-20250909120000" >/dev/null 2>&1; then
        log_pass "Valid Backstage ID validation passed"
    else
        log_fail "Valid Backstage ID validation failed"
    fi
    
    # Test validate command with invalid ID
    if ! python3 "$PROJECT_ROOT/scripts/manage-backstage-resources.py" validate "invalid-format" >/dev/null 2>&1; then
        log_pass "Invalid Backstage ID validation correctly failed"
    else
        log_fail "Invalid Backstage ID validation should have failed"
    fi
    
    cleanup_test_env "$test_dir"
}

test_integration_workflow() {
    log_test "Testing integration workflow"
    
    local test_dir
    test_dir=$(setup_test_env)
    
    cd "$test_dir"
    
    # Step 1: Create Backstage resource
    cat > a-records.yaml << 'EOF'
integration_resource:
  fqdn: "integration.example.com"
  ip_addr: "10.1.1.99"
  view: "default"
  ttl: 3600
  comment: "Integration test | Backstage ID: integration-test-test-20250909120000"
  ea_tags:
    BackstageId: "integration-test-test-20250909120000"
    BackstageEntity: "integration-test"
    CreatedBy: "backstage"
    Owner: "test-team"
EOF
    
    # Step 2: Merge it
    if python3 "$PROJECT_ROOT/scripts/merge-backstage-config.py" test-env --source-dir . --strategy backstage-wins >/dev/null 2>&1; then
        log_pass "Integration step 1: Merge succeeded"
        
        # Step 3: Find the resource
        local find_output
        find_output=$(python3 "$PROJECT_ROOT/scripts/manage-backstage-resources.py" --config-path environments/test-env find integration-test 2>/dev/null || echo "")
        
        if echo "$find_output" | grep -q "integration-test-test-20250909120000"; then
            log_pass "Integration step 2: Found merged resource"
            
            # Step 4: Generate cleanup config
            local cleanup_output
            cleanup_output=$(python3 "$PROJECT_ROOT/scripts/manage-backstage-resources.py" --config-path environments/test-env cleanup integration-test-test-20250909120000 2>/dev/null || echo "")
            
            if echo "$cleanup_output" | grep -q "resources_to_remove"; then
                log_pass "Integration step 3: Generated cleanup config"
                
                if echo "$cleanup_output" | grep -q "infoblox_a_record"; then
                    log_pass "Integration step 4: Cleanup config contains correct Terraform resources"
                else
                    log_fail "Integration step 4: Cleanup config missing Terraform resources"
                fi
            else
                log_fail "Integration step 3: Failed to generate cleanup config"
            fi
        else
            log_fail "Integration step 2: Could not find merged resource"
        fi
    else
        log_fail "Integration step 1: Merge failed"
    fi
    
    cleanup_test_env "$test_dir"
}

run_all_tests() {
    echo "🚀 Starting Manual Test Suite for Backstage Scripts"
    echo "=================================================="
    
    # Basic checks
    test_script_exists
    test_script_permissions
    test_python_dependencies
    test_fixtures_valid
    
    # Help/usage tests
    test_merge_script_help
    test_manage_script_help
    test_cleanup_script_help
    
    # Functionality tests
    test_merge_script_basic
    test_manage_script_basic
    test_integration_workflow
    
    # Print summary
    echo ""
    echo "=================================================="
    echo "🎯 Test Results Summary:"
    echo "   ✅ Passed: $PASSED"
    echo "   ❌ Failed: $FAILED"
    echo "   📊 Total:  $((PASSED + FAILED))"
    
    if [[ $FAILED -eq 0 ]]; then
        echo ""
        echo "🎉 All tests passed! Your scripts are working correctly."
        return 0
    else
        echo ""
        echo "⚠️  $FAILED test(s) failed. Please check the output above."
        return 1
    fi
}

# Run tests
run_all_tests
