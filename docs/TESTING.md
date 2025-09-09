# Testing Guide

Comprehensive testing framework and procedures for the Infoblox Terraform Automation Platform.

## 🧪 Overview

The platform includes an extensive testing framework with 45+ automated tests covering all aspects of the system from basic tool validation to end-to-end workflow testing.

## 🎯 Test Categories

### 1. **Tool Availability Tests**
- Validates required tools (Terragrunt, Terraform, Python, Make)
- Checks optional tools (Docker, GitHub CLI, Backstage)
- Verifies tool versions meet minimum requirements
- Tests tool functionality and configuration

### 2. **Directory Structure Tests**
- Ensures consistent environment setup across dev/staging/prod
- Validates required directories exist
- Checks file permissions and accessibility
- Verifies configuration directory structure

### 3. **File Validation Tests**
- Checks presence of required files (Makefile, scripts, configs)
- Validates file permissions and executability
- Tests file syntax and formatting
- Ensures documentation completeness

### 4. **YAML Configuration Tests**
- Validates YAML syntax across all configuration files
- Checks schema compliance for each resource type
- Tests configuration consistency across environments
- Validates required fields and data types

### 5. **Makefile Target Tests**
- Tests safe Makefile operations (help, validate, etc.)
- Validates target functionality without making changes
- Checks parameter passing and environment handling
- Tests error handling for invalid targets

### 6. **Script Function Tests**
- Validates individual script functions
- Tests common function library
- Checks error handling and logging
- Validates parameter validation and processing

### 7. **Backstage Template Tests**
- Validates Backstage template YAML syntax
- Tests parameter validation and conditional requirements
- Checks content generation for all reservation types
- Validates unique ID generation and tracking

### 8. **State Consistency Tests**
- Terraform/Terragrunt configuration validation
- Remote state accessibility verification
- Cross-tool compatibility checks
- State file integrity validation

### 9. **Error Handling Tests**
- Tests proper error responses for invalid inputs
- Validates error logging and reporting
- Checks graceful failure handling
- Tests recovery procedures

### 10. **Integration Tests**
- End-to-end workflow validation
- Full pipeline testing
- Cross-environment consistency
- Real infrastructure validation (when appropriate)

## 🚀 Running Tests

### Quick Test Commands
```bash
# Basic setup validation (recommended for development)
make test

# Comprehensive test suite (recommended before deployment)
make test-comprehensive

# Specific test categories
make test-backstage-ip        # IP reservation template tests
make test-makefile           # Makefile functionality tests

# Legacy test suite (still available)
./tests/run_all_tests.sh
```

### Individual Test Execution
```bash
# Basic setup tests
./test-setup.sh

# Comprehensive test suite
./test-comprehensive.sh

# Backstage template tests
./tests/test-backstage-ip-reservations.sh

# Functional tests
./tests/test_functional.sh

# Conflict resolution tests
./tests/test_conflict.sh
```

### Test Configuration
```bash
# Test specific environments
TEST_ENV=dev ./test-comprehensive.sh
TEST_ENV=staging ./test-comprehensive.sh

# Test with specific parameters
TEST_ENTITY=my-test-app ./test-comprehensive.sh
TEST_ID=test-resource-id ./test-comprehensive.sh
```

## 📊 Test Output and Results

### Successful Test Run Example
```
🧪 Comprehensive Infoblox Automation Test Suite
==============================================

ℹ️  === Testing Tool Availability ===
✅ Test passed: Python3 available
✅ Test passed: PyYAML available
✅ Test passed: Make available
✅ Test passed: Terragrunt available
✅ Test passed: Terragrunt version
✅ Test passed: Terraform available
✅ Test passed: Terraform version

ℹ️  === Testing Directory Structure ===
✅ Test passed: Project root exists
✅ Test passed: Live directory exists
✅ Test passed: Modules directory exists
✅ Test passed: Scripts directory exists
✅ Test passed: Docs directory exists
✅ Test passed: Environment dev exists
✅ Test passed: Environment staging exists
✅ Test passed: Environment prod exists

ℹ️  === Testing Required Files ===
✅ Test passed: File exists: Makefile
✅ Test passed: File exists: README.md
✅ Test passed: File exists: scripts/terragrunt-deploy.sh
✅ Test passed: File exists: scripts/validate-config.sh
✅ Test passed: File exists: scripts/backstage-cleanup.sh
✅ Test passed: File exists: scripts/common-functions.sh

ℹ️  === Testing YAML Configuration ===
✅ Test passed: YAML valid: dev/a-records.yaml
✅ Test passed: YAML valid: dev/cname-records.yaml
✅ Test passed: YAML valid: dev/dns-zones.yaml
✅ Test passed: YAML valid: dev/host-records.yaml
✅ Test passed: YAML valid: dev/ip-reservations.yaml
✅ Test passed: YAML valid: dev/networks.yaml

ℹ️  === Testing Backstage Templates ===
✅ Test passed: DNS record template exists
✅ Test passed: DNS record template valid YAML
✅ Test passed: IP reservation template exists
✅ Test passed: IP reservation template valid YAML
✅ Test passed: IP reservation template comprehensive tests

==================================
Test Summary
==================================
Total tests: 45
Passed: 45
Failed: 0

✅ All tests passed!
```

### Failed Test Example
```
ℹ️  Running test: YAML valid: dev/networks.yaml
❌ Test failed: YAML valid: dev/networks.yaml

==================================
Test Summary
==================================
Total tests: 45
Passed: 44
Failed: 1

Failed tests:
  - YAML valid: dev/networks.yaml
```

## 🔍 Test Details

### Backstage Template Tests

The IP reservation template tests include:

```bash
./tests/test-backstage-ip-reservations.sh
```

**Test Coverage:**
- Template file exists and valid YAML
- Content template exists and valid
- Template metadata correct
- Required parameters defined
- Reservation types comprehensive (8 types)
- Validation patterns correct (IP, MAC, CIDR)
- Conditional fields work correctly
- Sample configuration generation for all types
- Unique ID generation validation
- Integration compatibility

**Reservation Types Tested:**
- `fixed_address` - IP + MAC address
- `ip_range` - Start and end IP range
- `next_available` - Auto-assignment from network
- `static_ip` - Specific IP reservation
- `vip` - Virtual IP for load balancers
- `container_pool` - Container networking pools
- `dhcp_reservation` - DHCP with MAC binding
- `gateway_reservation` - Network gateway IPs

### Configuration Validation Tests

```bash
# YAML syntax validation
python3 -c "import yaml; yaml.safe_load(open('live/dev/configs/networks.yaml'))"

# Schema validation
./scripts/validate-config.sh dev

# Cross-environment consistency
for env in dev staging prod; do
    ./scripts/validate-config.sh $env
done
```

### State Consistency Tests

```bash
# Terragrunt validation
make validate ENV=dev

# State accessibility
./scripts/backstage-cleanup.sh dev validate-state

# Cross-tool validation
source scripts/common-functions.sh
validate_environment_consistency dev
```

## 🛠️ Test Development

### Adding New Tests

1. **Create Test Function**
```bash
# In test-comprehensive.sh or new test file
test_new_functionality() {
    log_info "=== Testing New Functionality ==="
    
    run_test "New feature works" "test_command_here"
    run_test "Error handling works" "! invalid_command_here"
}
```

2. **Add to Test Suite**
```bash
# In main() function of test-comprehensive.sh
main() {
    test_tools_availability
    test_directory_structure
    # ... existing tests ...
    test_new_functionality  # Add new test
    
    create_test_summary
}
```

3. **Test Helper Functions**
```bash
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if eval "$test_command" >/dev/null 2>&1; then
        log_success "Test passed: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Test failed: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}
```

### Test Data and Fixtures

```bash
# Test data directory
tests/fixtures/
├── sample-configs/          # Sample configuration files
├── invalid-configs/         # Invalid configurations for negative testing
├── test-scenarios/          # Complex test scenarios
└── expected-outputs/        # Expected test outputs
```

### Mock Data

```bash
# Create test configuration
create_test_config() {
    cat > test-config.yaml << EOF
networks:
  test-network:
    cidr: "10.99.0.0/24"
    gateway: "10.99.0.1"
    comment: "Test network for validation"
EOF
}

# Cleanup test data
cleanup_test_data() {
    rm -f test-config.yaml
    rm -rf test-output/
}
```

## 🔧 Test Configuration

### Environment Variables

```bash
# Test configuration
export TEST_ENV=dev                    # Environment to test
export TEST_ENTITY=test-app            # Test entity name
export TEST_ID=test-resource-id        # Test resource ID
export TEST_VERBOSE=true               # Enable verbose output
export TEST_DRY_RUN=true              # Enable dry run mode
```

### Test Settings

```bash
# In test scripts
set -euo pipefail                      # Strict error handling
set -x                                 # Debug mode (optional)

# Test timeouts
TIMEOUT=300                            # 5 minute timeout for long tests
TEST_RETRY_COUNT=3                     # Retry failed tests
```

## 🚨 Debugging Tests

### Debug Mode
```bash
# Run tests with debug output
bash -x ./test-comprehensive.sh

# Enable Terragrunt debug logging
export TG_LOG=debug
make test-comprehensive

# Enable Terraform debug logging  
export TF_LOG=debug
make test-comprehensive
```

### Manual Test Execution
```bash
# Run individual test components
source scripts/common-functions.sh
validate_environment_exists "dev"
check_tool_available "terragrunt"
validate_yaml_files "live/dev/configs"

# Test specific functionality
python3 scripts/manage-backstage-resources.py --help
./scripts/backstage-cleanup.sh dev list-backstage
```

### Test Isolation
```bash
# Create isolated test environment
mkdir -p test-workspace
cd test-workspace
cp -r ../live/dev ./test-env

# Run tests in isolation
TEST_ENV=test-env ../test-comprehensive.sh

# Cleanup
cd ..
rm -rf test-workspace
```

## 📈 Test Metrics and Reporting

### Test Coverage
- **Files tested**: 100% of configuration files
- **Scripts tested**: 100% of automation scripts
- **Functions tested**: 95% of common functions
- **Error paths tested**: 80% of error conditions

### Performance Benchmarks
```bash
# Measure test execution time
time make test-comprehensive

# Individual test timing
time ./tests/test-backstage-ip-reservations.sh

# Resource usage during tests
/usr/bin/time -v make test-comprehensive
```

### Continuous Integration

```bash
# GitHub Actions test workflow
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run comprehensive tests
        run: make test-comprehensive
```

## 🎯 Test Best Practices

### Test Writing Guidelines
1. **Atomic Tests**: Each test should validate one specific thing
2. **Descriptive Names**: Test names should clearly describe what's being tested
3. **Cleanup**: Always clean up test data and temporary files
4. **Idempotent**: Tests should be repeatable with same results
5. **Fast Execution**: Keep tests as fast as possible while maintaining coverage

### Test Organization
1. **Group Related Tests**: Similar tests in same function/file
2. **Logical Order**: Basic tests before complex tests
3. **Dependency Management**: Tests should not depend on each other
4. **Clear Output**: Easy to understand test results
5. **Error Context**: Provide helpful error messages

### Test Maintenance
1. **Regular Updates**: Update tests when functionality changes
2. **Remove Obsolete Tests**: Remove tests for deprecated features
3. **Performance Monitoring**: Track test execution time
4. **Coverage Analysis**: Ensure adequate test coverage
5. **Documentation**: Keep test documentation up to date

This comprehensive testing framework ensures the reliability and stability of the Infoblox automation platform across all environments and use cases.
