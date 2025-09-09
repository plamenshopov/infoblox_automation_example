#!/bin/bash
#
# Test Conflict Resolution Scenarios
#

set -e

echo "⚔️ Testing Conflict Resolution"
echo "=============================="

# Create temporary test environment
TEST_DIR=$(mktemp -d)
ENV_DIR="$TEST_DIR/live/dev/configs"
mkdir -p "$ENV_DIR"

echo "📁 Test directory: $TEST_DIR"

# Create conflicting configurations
cat > "$ENV_DIR/a-records.yaml" << 'EOF'
# Existing configuration
api_server:
  fqdn: "api.example.com"
  ip_addr: "10.1.1.50"
  view: "default"
  ttl: 3600
  comment: "Existing API server"
EOF

cat > "$TEST_DIR/a-records.yaml" << 'EOF'
# Backstage wants to use the same key
api_server:
  fqdn: "api.example.com" 
  ip_addr: "10.1.1.100"
  view: "default"
  ttl: 7200
  comment: "New API server | Backstage ID: test-api-dev-20250909120000"
  ea_tags:
    BackstageId: "test-api-dev-20250909120000"
EOF

echo "✅ Created conflicting configurations"

# Test different conflict strategies
cd "$TEST_DIR"

echo ""
echo "🔧 Testing backstage-wins strategy..."
python3 /mnt/data2/websites/infoblox/scripts/merge-backstage-config.py \
    dev \
    --source-dir . \
    --strategy backstage-wins

if grep -q "10.1.1.100" "$ENV_DIR/a-records.yaml"; then
    echo "✅ Backstage-wins strategy worked correctly"
else
    echo "❌ Backstage-wins strategy failed"
    exit 1
fi

# Reset for next test
cat > "$ENV_DIR/a-records.yaml" << 'EOF'
api_server:
  fqdn: "api.example.com"
  ip_addr: "10.1.1.50"
  view: "default"
  ttl: 3600
  comment: "Existing API server"
EOF

echo ""
echo "🛡️ Testing manual-protected strategy..."
python3 /mnt/data2/websites/infoblox/scripts/merge-backstage-config.py \
    dev \
    --source-dir . \
    --strategy manual-protected

if grep -q "10.1.1.50" "$ENV_DIR/a-records.yaml"; then
    echo "✅ Manual-protected strategy preserved existing configuration"
else
    echo "❌ Manual-protected strategy failed"
    exit 1
fi

# Test fail-on-conflict strategy
echo ""
echo "💥 Testing fail-on-conflict strategy..."
if ! python3 /mnt/data2/websites/infoblox/scripts/merge-backstage-config.py \
    dev \
    --source-dir . \
    --strategy fail-on-conflict \
    >/dev/null 2>&1; then
    echo "✅ Fail-on-conflict strategy correctly detected and failed on conflict"
else
    echo "❌ Fail-on-conflict strategy should have failed"
    exit 1
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "🎉 All conflict resolution tests passed!"
echo ""
echo "📋 Strategies tested:"
echo "   ✅ backstage-wins: Overwrites existing with Backstage data"
echo "   ✅ manual-protected: Preserves manually created resources"
echo "   ✅ fail-on-conflict: Fails safely when conflicts detected"
