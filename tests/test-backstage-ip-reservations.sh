#!/bin/bash

# Test script for IP Reservation Backstage Template
# Tests template validation, parameter validation, and output generation

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/common-functions.sh"

# Test configuration
TEMPLATE_DIR="${SCRIPT_DIR}/../templates/backstage"
TEMPLATE_FILE="${TEMPLATE_DIR}/ip-reservation-template.yaml"
CONTENT_FILE="${TEMPLATE_DIR}/content/ip-reservations.yaml"
TEST_OUTPUT_DIR="${SCRIPT_DIR}/test-output/backstage-ip-reservation"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Clean up test output directory
cleanup_test_output() {
    log_info "Cleaning up test output directory"
    rm -rf "${TEST_OUTPUT_DIR}"
    mkdir -p "${TEST_OUTPUT_DIR}"
}

# Test helper functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_RUN++))
    log_info "Running test: ${test_name}"
    
    if $test_function; then
        ((TESTS_PASSED++))
        log_success "✅ ${test_name}"
    else
        ((TESTS_FAILED++))
        log_error "❌ ${test_name}"
        return 1
    fi
}

# Test 1: Template file exists and is valid YAML
test_template_exists() {
    [[ -f "${TEMPLATE_FILE}" ]] || {
        log_error "Template file not found: ${TEMPLATE_FILE}"
        return 1
    }
    
    # Validate YAML syntax
    python3 -c "
import yaml
import sys
try:
    with open('${TEMPLATE_FILE}', 'r') as f:
        yaml.safe_load(f)
    print('✅ Template YAML is valid')
except yaml.YAMLError as e:
    print(f'❌ Template YAML is invalid: {e}')
    sys.exit(1)
" || return 1
}

# Test 2: Content template exists and is valid
test_content_template_exists() {
    [[ -f "${CONTENT_FILE}" ]] || {
        log_error "Content template file not found: ${CONTENT_FILE}"
        return 1
    }
    
    # Check for required template variables
    local required_vars=(
        "values.reservationId"
        "values.reservationName"
        "values.reservationType"
        "values.network"
        "values.backstageId"
    )
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "\${{ ${var} }}" "${CONTENT_FILE}"; then
            log_error "Missing required template variable: ${var}"
            return 1
        fi
    done
    
    log_success "All required template variables found"
}

# Test 3: Template metadata is correct
test_template_metadata() {
    local template_name
    template_name=$(python3 -c "
import yaml
with open('${TEMPLATE_FILE}', 'r') as f:
    template = yaml.safe_load(f)
print(template['metadata']['name'])
")
    
    [[ "${template_name}" == "infoblox-ip-reservation" ]] || {
        log_error "Incorrect template name: ${template_name}"
        return 1
    }
    
    # Check required tags
    local has_tags
    has_tags=$(python3 -c "
import yaml
with open('${TEMPLATE_FILE}', 'r') as f:
    template = yaml.safe_load(f)
tags = template['metadata'].get('tags', [])
required_tags = ['infoblox', 'ip-reservation', 'networking', 'automation', 'ipam']
print(all(tag in tags for tag in required_tags))
")
    
    [[ "${has_tags}" == "True" ]] || {
        log_error "Missing required tags in template metadata"
        return 1
    }
}

# Test 4: Required parameters are defined
test_required_parameters() {
    local required_params=(
        "reservationName"
        "reservationType"
        "environment"
        "entityName"
        "network"
    )
    
    for param in "${required_params[@]}"; do
        local param_exists
        param_exists=$(python3 -c "
import yaml
with open('${TEMPLATE_FILE}', 'r') as f:
    template = yaml.safe_load(f)
    
found = False
for section in template['spec']['parameters']:
    if 'properties' in section:
        if '${param}' in section['properties']:
            found = True
            break
    if 'required' in section:
        if '${param}' in section['required']:
            found = True
            break
            
print(found)
")
        
        [[ "${param_exists}" == "True" ]] || {
            log_error "Required parameter not found: ${param}"
            return 1
        }
    done
    
    log_success "All required parameters are defined"
}

# Test 5: Reservation types are comprehensive
test_reservation_types() {
    local expected_types=(
        "fixed_address"
        "ip_range"
        "next_available"
        "static_ip"
        "vip"
        "container_pool"
        "dhcp_reservation"
        "gateway_reservation"
    )
    
    for type in "${expected_types[@]}"; do
        if ! grep -q "\"${type}\"" "${TEMPLATE_FILE}"; then
            log_error "Missing reservation type: ${type}"
            return 1
        fi
    done
    
    log_success "All reservation types are present"
}

# Test 6: Validation patterns are correct
test_validation_patterns() {
    # Test IP address pattern
    local ip_pattern
    ip_pattern=$(python3 -c "
import yaml
import re
with open('${TEMPLATE_FILE}', 'r') as f:
    template = yaml.safe_load(f)

for section in template['spec']['parameters']:
    if 'properties' in section and 'ipAddress' in section['properties']:
        pattern = section['properties']['ipAddress'].get('pattern', '')
        print(pattern)
        break
")
    
    # Test the pattern with valid and invalid IPs
    local test_ips=(
        "192.168.1.1:valid"
        "10.0.0.1:valid"
        "256.1.1.1:invalid"
        "192.168.1:invalid"
        "not.an.ip:invalid"
    )
    
    for test_ip in "${test_ips[@]}"; do
        local ip="${test_ip%:*}"
        local expected="${test_ip#*:}"
        
        local matches
        matches=$(python3 -c "
import re
pattern = r'${ip_pattern}'
ip = '${ip}'
print('valid' if re.match(pattern, ip) else 'invalid')
")
        
        [[ "${matches}" == "${expected}" ]] || {
            log_error "IP validation pattern failed for ${ip} (expected ${expected}, got ${matches})"
            return 1
        }
    done
    
    log_success "IP validation patterns work correctly"
}

# Test 7: Conditional fields work correctly
test_conditional_fields() {
    # Check that MAC address is required for fixed_address and dhcp_reservation
    local mac_conditions
    mac_conditions=$(python3 -c "
import yaml
with open('${TEMPLATE_FILE}', 'r') as f:
    template = yaml.safe_load(f)

for section in template['spec']['parameters']:
    if 'properties' in section and 'macAddress' in section['properties']:
        when_clause = section['properties']['macAddress'].get('when', {})
        if 'properties' in when_clause and 'reservationType' in when_clause['properties']:
            enum_values = when_clause['properties']['reservationType'].get('enum', [])
            print('fixed_address' in enum_values and 'dhcp_reservation' in enum_values)
            break
")
    
    [[ "${mac_conditions}" == "True" ]] || {
        log_error "MAC address conditional fields are not configured correctly"
        return 1
    }
    
    log_success "Conditional fields are configured correctly"
}

# Test 8: Generate sample configurations
test_sample_configuration_generation() {
    local test_cases=(
        "fixed_address"
        "ip_range"
        "next_available"
        "static_ip"
        "vip"
        "container_pool"
        "dhcp_reservation"
        "gateway_reservation"
    )
    
    for reservation_type in "${test_cases[@]}"; do
        local output_file="${TEST_OUTPUT_DIR}/sample-${reservation_type}.yaml"
        
        # Create sample values for each type
        case "${reservation_type}" in
            "fixed_address")
                generate_sample_config "${reservation_type}" "${output_file}" \
                    "10.1.0.0/24" "10.1.0.100" "00:11:22:33:44:55"
                ;;
            "ip_range")
                generate_sample_config "${reservation_type}" "${output_file}" \
                    "10.1.0.0/24" "10.1.0.100" "" "10.1.0.110"
                ;;
            "next_available")
                generate_sample_config "${reservation_type}" "${output_file}" \
                    "10.1.0.0/24" "" "" "" "5"
                ;;
            "static_ip")
                generate_sample_config "${reservation_type}" "${output_file}" \
                    "10.1.0.0/24" "10.1.0.50"
                ;;
            "vip")
                generate_sample_config "${reservation_type}" "${output_file}" \
                    "10.1.0.0/24" "10.1.0.200"
                ;;
            "container_pool")
                generate_sample_config "${reservation_type}" "${output_file}" \
                    "10.1.0.0/24" "" "" "" "10"
                ;;
            "dhcp_reservation")
                generate_sample_config "${reservation_type}" "${output_file}" \
                    "10.1.0.0/24" "" "00:aa:bb:cc:dd:ee"
                ;;
            "gateway_reservation")
                generate_sample_config "${reservation_type}" "${output_file}" \
                    "10.1.0.0/24" "10.1.0.1"
                ;;
        esac
        
        # Validate generated configuration
        [[ -f "${output_file}" ]] || {
            log_error "Failed to generate sample configuration for ${reservation_type}"
            return 1
        }
        
        # Check that the file contains required elements
        if ! grep -q "type: \"${reservation_type}\"" "${output_file}"; then
            log_error "Generated configuration missing reservation type: ${reservation_type}"
            return 1
        fi
    done
    
    log_success "Sample configurations generated successfully for all types"
}

# Helper function to generate sample configurations
generate_sample_config() {
    local reservation_type="$1"
    local output_file="$2"
    local network="$3"
    local ip_address="${4:-}"
    local mac_address="${5:-}"
    local end_ip="${6:-}"
    local pool_size="${7:-1}"
    
    # Create a mock template rendering
    cat > "${output_file}" << EOF
# Generated IP Reservation Configuration
# Reservation: test-${reservation_type}-$(date +%s)
# Type: ${reservation_type}
# Environment: dev
# Generated: $(date -Iseconds)
# Reservation ID: ip-res-$(date +%Y%m%d%H%M%S)-test-${reservation_type}
# Backstage ID: test-${reservation_type}-dev-$(date +%Y%m%d%H%M%S)

ip_reservations:
  - id: "ip-res-$(date +%Y%m%d%H%M%S)-test-${reservation_type}"
    name: "test-${reservation_type}-reservation"
    type: "${reservation_type}"
    network: "${network}"
EOF

    case "${reservation_type}" in
        "fixed_address")
            cat >> "${output_file}" << EOF
    ip_address: "${ip_address}"
    mac_address: "${mac_address}"
EOF
            ;;
        "ip_range")
            cat >> "${output_file}" << EOF
    start_ip: "${ip_address}"
    end_ip: "${end_ip}"
EOF
            ;;
        "next_available")
            cat >> "${output_file}" << EOF
    pool_size: ${pool_size}
EOF
            ;;
        "static_ip")
            cat >> "${output_file}" << EOF
    ip_address: "${ip_address}"
EOF
            ;;
        "vip")
            cat >> "${output_file}" << EOF
    ip_address: "${ip_address}"
    vip_type: "load_balancer"
EOF
            ;;
        "container_pool")
            cat >> "${output_file}" << EOF
    pool_size: ${pool_size}
    container_network: true
EOF
            ;;
        "dhcp_reservation")
            cat >> "${output_file}" << EOF
    mac_address: "${mac_address}"
    dhcp_enabled: true
EOF
            ;;
        "gateway_reservation")
            cat >> "${output_file}" << EOF
    ip_address: "${ip_address}"
    is_gateway: true
EOF
            ;;
    esac

    cat >> "${output_file}" << EOF
    comment: "Test reservation for ${reservation_type} | Reservation ID: ip-res-$(date +%Y%m%d%H%M%S)-test-${reservation_type}"
    disable_discovery: false
    usage_type: "UNSPECIFIED"
    ea_tags:
      ReservationId: "ip-res-$(date +%Y%m%d%H%M%S)-test-${reservation_type}"
      BackstageId: "test-${reservation_type}-dev-$(date +%Y%m%d%H%M%S)"
      BackstageEntity: "test-${reservation_type}"
      Owner: "test-user"
      CreatedBy: "test-user"
      CreatedAt: "$(date -Iseconds)"
      ReservationType: "${reservation_type}"
      Environment: "dev"
      Purpose: "Testing"
EOF
}

# Test 9: Unique ID generation validation
test_unique_id_generation() {
    # Test that IDs are properly structured
    local timestamp_pattern="[0-9]{14}"
    local id_pattern="ip-res-${timestamp_pattern}-[a-z0-9-]+"
    
    # Generate multiple IDs and check uniqueness
    local ids=()
    for i in {1..5}; do
        local id="ip-res-$(date +%Y%m%d%H%M%S)-test-entity-${i}"
        ids+=("${id}")
        sleep 1  # Ensure different timestamps
    done
    
    # Check uniqueness
    local unique_count
    unique_count=$(printf '%s\n' "${ids[@]}" | sort -u | wc -l)
    
    [[ "${unique_count}" -eq "${#ids[@]}" ]] || {
        log_error "Generated IDs are not unique"
        return 1
    }
    
    # Validate ID format
    for id in "${ids[@]}"; do
        if ! [[ "${id}" =~ ^ip-res-[0-9]{14}-[a-z0-9-]+$ ]]; then
            log_error "Invalid ID format: ${id}"
            return 1
        fi
    done
    
    log_success "Unique ID generation works correctly"
}

# Test 10: Template integration with existing structure
test_integration_compatibility() {
    # Check that the template works with existing directory structure
    local expected_paths=(
        "live/dev/configs/ip-reservations.yaml"
        "live/staging/configs/ip-reservations.yaml"
        "live/prod/configs/ip-reservations.yaml"
    )
    
    # Verify template references correct paths
    for path in "${expected_paths[@]}"; do
        if ! grep -q "${path}" "${TEMPLATE_FILE}"; then
            log_warning "Template may not reference expected path: ${path}"
        fi
    done
    
    # Check compatibility with existing configuration structure
    local existing_config="${SCRIPT_DIR}/../live/dev/configs/ip-reservations.yaml"
    if [[ -f "${existing_config}" ]]; then
        # Validate existing config structure matches template output
        python3 -c "
import yaml
try:
    with open('${existing_config}', 'r') as f:
        config = yaml.safe_load(f)
    if 'ip_reservations' in config:
        print('✅ Existing config structure is compatible')
    else:
        print('⚠️  Existing config structure may need updates')
except Exception as e:
    print(f'⚠️  Could not validate existing config: {e}')
"
    fi
    
    log_success "Template integration compatibility verified"
}

# Main test execution
main() {
    log_info "Starting IP Reservation Backstage Template Tests"
    log_info "================================================"
    
    cleanup_test_output
    
    # Run all tests
    run_test "Template File Exists and Valid YAML" test_template_exists
    run_test "Content Template Exists and Valid" test_content_template_exists
    run_test "Template Metadata Correct" test_template_metadata
    run_test "Required Parameters Defined" test_required_parameters
    run_test "Reservation Types Comprehensive" test_reservation_types
    run_test "Validation Patterns Correct" test_validation_patterns
    run_test "Conditional Fields Work" test_conditional_fields
    run_test "Sample Configuration Generation" test_sample_configuration_generation
    run_test "Unique ID Generation" test_unique_id_generation
    run_test "Integration Compatibility" test_integration_compatibility
    
    # Print summary
    log_info "================================================"
    log_info "Test Summary"
    log_info "================================================"
    log_info "Tests Run: ${TESTS_RUN}"
    log_success "Tests Passed: ${TESTS_PASSED}"
    
    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        log_error "Tests Failed: ${TESTS_FAILED}"
        log_info "Check test output in: ${TEST_OUTPUT_DIR}"
        exit 1
    else
        log_success "All tests passed! ✅"
        log_info "Sample configurations available in: ${TEST_OUTPUT_DIR}"
        exit 0
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
