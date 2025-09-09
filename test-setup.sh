#!/bin/bash

# Quick setup test script for Terragrunt-only structure
# Usage: ./test-setup.sh

set -e

echo "🧪 Testing Infoblox Terragrunt Automation Setup"
echo "=============================================="

# Test 1: Check required tools
echo "✅ Checking required tools..."
command -v terragrunt >/dev/null 2>&1 || { echo "❌ terragrunt not found"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ python3 not found"; exit 1; }
echo "✅ Tools check passed"

# Test 2: Check directory structure
echo "✅ Checking directory structure..."
dirs=("live/dev" "live/staging" "live/prod" "modules/ipam" "modules/dns" "scripts" "docs")
for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ Directory $dir not found"
        exit 1
    fi
done
echo "✅ Directory structure check passed"

# Test 3: Check required files
echo "✅ Checking required files..."
files=(
    "live/dev/terragrunt.hcl"
    "live/dev/configs/networks.yaml"
    "scripts/terragrunt-deploy.sh"
    "scripts/validate-config.sh"
    "scripts/backstage-cleanup.sh"
    "Makefile"
    "README.md"
    "docs/CLEANUP_GUIDE.md"
)

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ File $file not found"
        exit 1
    fi
done
echo "✅ Required files check passed"

# Test 4: Check script permissions
echo "✅ Checking script permissions..."
if [ ! -x "scripts/terragrunt-deploy.sh" ]; then
    echo "❌ scripts/terragrunt-deploy.sh is not executable"
    exit 1
fi
if [ ! -x "scripts/validate-config.sh" ]; then
    echo "❌ scripts/validate-config.sh is not executable"
    exit 1
fi
if [ ! -x "scripts/backstage-cleanup.sh" ]; then
    echo "❌ scripts/backstage-cleanup.sh is not executable"
    exit 1
fi
echo "✅ Script permissions check passed"

# Test 5: Validate Terragrunt syntax
echo "✅ Checking Terragrunt configuration..."
for env in dev staging prod; do
    echo "  Checking $env environment..."
    cd "live/$env"
    terragrunt validate >/dev/null 2>&1 || { echo "❌ Terragrunt validation failed for $env"; exit 1; }
    cd ../..
done
echo "✅ Terragrunt syntax check passed"

# Test 6: Validate YAML configuration files
echo "✅ Checking YAML configuration files..."
if command -v python3 >/dev/null 2>&1; then
    python3 -c "import yaml" 2>/dev/null || { echo "⚠️  PyYAML not installed - skipping YAML validation"; }
    
    if python3 -c "import yaml" 2>/dev/null; then
        for env in dev staging prod; do
            config_dir="live/$env/configs"
            if [ -d "$config_dir" ]; then
                for yaml_file in "$config_dir"/*.yaml; do
                    if [ -f "$yaml_file" ]; then
                        python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null || { echo "❌ Invalid YAML: $yaml_file"; exit 1; }
                    fi
                done
            fi
        done
        echo "✅ YAML validation passed"
    fi
fi

# Test 7: Check Makefile
echo "✅ Checking Makefile..."
if command -v make >/dev/null 2>&1; then
    make help >/dev/null 2>&1 || { echo "❌ Makefile has issues"; exit 1; }
    echo "✅ Makefile check passed"
else
    echo "⚠️  make not found - skipping Makefile test"
fi

# Test 8: Test cleanup functionality
echo "✅ Testing cleanup functionality..."
./scripts/backstage-cleanup.sh list-backstage dev >/dev/null 2>&1 || { echo "❌ Cleanup script failed"; exit 1; }
echo "✅ Cleanup functionality check passed"

echo ""
echo "🎉 All tests passed! Terragrunt setup is ready for use."
echo ""
echo "Next steps:"
echo "1. Copy terragrunt.hcl.example to terragrunt.hcl in each environment (if needed)"
echo "2. Configure your Infoblox connection details"
echo "3. Customize the YAML configuration files"
echo "4. Run: make tg-validate ENV=dev"
echo "5. Run: make tg-plan ENV=dev"
echo ""
echo "For cleanup operations, see docs/CLEANUP_GUIDE.md"
echo "For more information, see README.md"
