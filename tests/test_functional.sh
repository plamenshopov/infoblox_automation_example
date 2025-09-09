#!/bin/bash
#
# Simple Functional Test for Backstage Scripts
#

set -e

echo "🧪 Testing Backstage Scripts Functionality"
echo "=========================================="

# Create temporary test environment
TEST_DIR=$(mktemp -d)
ENV_DIR="$TEST_DIR/live/dev/configs"
mkdir -p "$ENV_DIR"

echo "📁 Test directory: $TEST_DIR"

# Step 1: Create a sample existing configuration
cat > "$ENV_DIR/a-records.yaml" << 'EOF'
# Existing A Records
legacy_server:
  fqdn: "legacy.example.com"
  ip_addr: "10.1.1.50"
  view: "default"
  ttl: 3600
  comment: "Legacy server - manually created"
  ea_tags:
    Owner: "ops-team"
    Environment: "dev"
EOF

echo "✅ Created existing configuration"

# Step 2: Create a new Backstage-generated file
cat > "$TEST_DIR/a-records.yaml" << 'EOF'
# Generated DNS Record Configuration
# Environment: dev
# Backstage ID: test-app-dev-20250909120000

test_app_api:
  fqdn: "api.test-app.example.com"
  ip_addr: "10.1.1.100"
  view: "default"
  ttl: 3600
  comment: "Test app API | Backstage ID: test-app-dev-20250909120000"
  ea_tags:
    Owner: "dev-team"
    CreatedBy: "backstage"
    CreatedAt: "2025-09-09T12:00:00Z"
    BackstageId: "test-app-dev-20250909120000"
    BackstageEntity: "test-app"
EOF

echo "✅ Created Backstage-generated configuration"

# Step 3: Test merge script
echo ""
echo "🔄 Testing merge functionality..."
cd "$TEST_DIR"

python3 /mnt/data2/websites/infoblox/scripts/merge-backstage-config.py \
    dev \
    --source-dir . \
    --strategy backstage-wins

if [[ $? -eq 0 ]]; then
    echo "✅ Merge script executed successfully"
else
    echo "❌ Merge script failed"
    exit 1
fi

# Step 4: Verify merge results
if [[ -f "$ENV_DIR/a-records.yaml" ]]; then
    echo "✅ Merged file exists"
    
    if grep -q "test_app_api" "$ENV_DIR/a-records.yaml"; then
        echo "✅ New Backstage resource was merged"
    else
        echo "❌ New resource was not found in merged file"
        exit 1
    fi
    
    if grep -q "legacy_server" "$ENV_DIR/a-records.yaml"; then
        echo "✅ Existing resource was preserved"
    else
        echo "❌ Existing resource was lost"
        exit 1
    fi
else
    echo "❌ Merged file was not created"
    exit 1
fi

# Step 5: Test resource management
echo ""
echo "🔍 Testing resource management..."

# List resources
LIST_OUTPUT=$(python3 /mnt/data2/websites/infoblox/scripts/manage-backstage-resources.py \
    --config-path "$ENV_DIR" \
    list \
    --format json)

if echo "$LIST_OUTPUT" | grep -q "test-app-dev-20250909120000"; then
    echo "✅ Resource manager found the merged Backstage resource"
else
    echo "❌ Resource manager did not find the Backstage resource"
    exit 1
fi

# Find resources by entity
FIND_OUTPUT=$(python3 /mnt/data2/websites/infoblox/scripts/manage-backstage-resources.py \
    --config-path "$ENV_DIR" \
    find test-app)

if echo "$FIND_OUTPUT" | grep -q "test-app-dev-20250909120000"; then
    echo "✅ Found resources by entity name"
else
    echo "❌ Could not find resources by entity"
    exit 1
fi

# Generate cleanup configuration
CLEANUP_OUTPUT=$(python3 /mnt/data2/websites/infoblox/scripts/manage-backstage-resources.py \
    --config-path "$ENV_DIR" \
    cleanup test-app-dev-20250909120000)

if echo "$CLEANUP_OUTPUT" | grep -q "resources_to_remove"; then
    echo "✅ Generated cleanup configuration"
    
    if echo "$CLEANUP_OUTPUT" | grep -q "infoblox_a_record"; then
        echo "✅ Cleanup config contains correct Terraform resource"
    else
        echo "❌ Cleanup config missing Terraform resource"
        exit 1
    fi
else
    echo "❌ Failed to generate cleanup configuration"
    exit 1
fi

# Step 6: Test ID validation
echo ""
echo "🔍 Testing ID validation..."

# Valid ID
if python3 /mnt/data2/websites/infoblox/scripts/manage-backstage-resources.py \
    validate "test-app-dev-20250909120000" >/dev/null 2>&1; then
    echo "✅ Valid ID validation passed"
else
    echo "❌ Valid ID validation failed"
    exit 1
fi

# Invalid ID
if ! python3 /mnt/data2/websites/infoblox/scripts/manage-backstage-resources.py \
    validate "invalid-format" >/dev/null 2>&1; then
    echo "✅ Invalid ID validation correctly failed"
else
    echo "❌ Invalid ID validation should have failed"
    exit 1
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "🎉 All tests passed! Your Backstage scripts are working correctly."
echo ""
echo "📋 What was tested:"
echo "   ✅ Merge script functionality"
echo "   ✅ Resource preservation during merge"
echo "   ✅ Backstage resource identification"
echo "   ✅ Resource listing and filtering"
echo "   ✅ Cleanup configuration generation"
echo "   ✅ Terraform resource name generation"
echo "   ✅ Backstage ID validation"
echo ""
echo "🚀 Your scripts are ready for production use!"
