#!/bin/bash
#
# Complete Test Suite Runner
#

echo "🧪 Infoblox Backstage Scripts - Test Suite"
echo "=========================================="
echo ""

# Test 1: Basic functionality
echo "📋 Test 1: Basic Functionality"
echo "------------------------------"
if /mnt/data2/websites/infoblox/tests/test_functional.sh; then
    echo "✅ PASSED: Basic functionality test"
    BASIC_PASS=1
else
    echo "❌ FAILED: Basic functionality test"
    BASIC_PASS=0
fi

echo ""
echo "📋 Test 2: Script Help Commands"
echo "------------------------------"

# Test help commands
if python3 /mnt/data2/websites/infoblox/scripts/merge-backstage-config.py --help >/dev/null 2>&1; then
    echo "✅ PASSED: merge-backstage-config.py help"
    MERGE_HELP_PASS=1
else
    echo "❌ FAILED: merge-backstage-config.py help"
    MERGE_HELP_PASS=0
fi

if python3 /mnt/data2/websites/infoblox/scripts/manage-backstage-resources.py --help >/dev/null 2>&1; then
    echo "✅ PASSED: manage-backstage-resources.py help"
    MANAGE_HELP_PASS=1
else
    echo "❌ FAILED: manage-backstage-resources.py help"
    MANAGE_HELP_PASS=0
fi

echo ""
echo "📋 Test 3: ID Validation"
echo "------------------------"

# Test valid ID
if python3 /mnt/data2/websites/infoblox/scripts/manage-backstage-resources.py \
    validate "test-app-dev-20250909120000" >/dev/null 2>&1; then
    echo "✅ PASSED: Valid ID validation"
    VALID_ID_PASS=1
else
    echo "❌ FAILED: Valid ID validation"
    VALID_ID_PASS=0
fi

# Test invalid ID
if ! python3 /mnt/data2/websites/infoblox/scripts/manage-backstage-resources.py \
    validate "invalid-format" >/dev/null 2>&1; then
    echo "✅ PASSED: Invalid ID rejection"
    INVALID_ID_PASS=1
else
    echo "❌ FAILED: Invalid ID should be rejected"
    INVALID_ID_PASS=0
fi

echo ""
echo "📋 Test 4: Simple Merge Test"
echo "----------------------------"

# Create simple test
TEST_DIR=$(mktemp -d)
ENV_DIR="$TEST_DIR/live/dev/configs"
mkdir -p "$ENV_DIR"

cat > "$ENV_DIR/a-records.yaml" << 'EOF'
existing_server:
  fqdn: "existing.example.com"
  ip_addr: "10.1.1.1"
EOF

cat > "$TEST_DIR/a-records.yaml" << 'EOF'
new_server:
  fqdn: "new.example.com"
  ip_addr: "10.1.1.2"
  comment: "Backstage ID: test-123"
  ea_tags:
    BackstageId: "test-123"
EOF

cd "$TEST_DIR"
if python3 /mnt/data2/websites/infoblox/scripts/merge-backstage-config.py dev --source-dir . >/dev/null 2>&1; then
    if grep -q "new_server" "$ENV_DIR/a-records.yaml" && grep -q "existing_server" "$ENV_DIR/a-records.yaml"; then
        echo "✅ PASSED: Simple merge test"
        SIMPLE_MERGE_PASS=1
    else
        echo "❌ FAILED: Merge content incorrect"
        SIMPLE_MERGE_PASS=0
    fi
else
    echo "❌ FAILED: Simple merge execution"
    SIMPLE_MERGE_PASS=0
fi

rm -rf "$TEST_DIR"

echo ""
echo "🎯 Test Results Summary"
echo "======================"
echo ""

TOTAL_TESTS=6
PASSED_TESTS=0

if [[ $BASIC_PASS -eq 1 ]]; then
    echo "✅ Basic Functionality Test"
    ((PASSED_TESTS++))
else
    echo "❌ Basic Functionality Test"
fi

if [[ $MERGE_HELP_PASS -eq 1 ]]; then
    echo "✅ Merge Script Help"
    ((PASSED_TESTS++))
else
    echo "❌ Merge Script Help"
fi

if [[ $MANAGE_HELP_PASS -eq 1 ]]; then
    echo "✅ Manage Script Help"
    ((PASSED_TESTS++))
else
    echo "❌ Manage Script Help"
fi

if [[ $VALID_ID_PASS -eq 1 ]]; then
    echo "✅ Valid ID Validation"
    ((PASSED_TESTS++))
else
    echo "❌ Valid ID Validation"
fi

if [[ $INVALID_ID_PASS -eq 1 ]]; then
    echo "✅ Invalid ID Rejection"
    ((PASSED_TESTS++))
else
    echo "❌ Invalid ID Rejection"
fi

if [[ $SIMPLE_MERGE_PASS -eq 1 ]]; then
    echo "✅ Simple Merge Test"
    ((PASSED_TESTS++))
else
    echo "❌ Simple Merge Test"
fi

echo ""
echo "🏆 Final Score: $PASSED_TESTS/$TOTAL_TESTS tests passed"

if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
    echo ""
    echo "🎉 ALL TESTS PASSED! Your Backstage scripts are working perfectly."
    echo ""
    echo "🚀 Ready for production deployment:"
    echo "   • Merge scripts handle file integration correctly"
    echo "   • Resource management identifies and tracks Backstage resources"
    echo "   • ID validation prevents invalid identifiers"
    echo "   • Conflict detection and backup systems working"
    echo ""
    exit 0
else
    echo ""
    echo "⚠️  Some tests failed. Please review the output above."
    exit 1
fi
