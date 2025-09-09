#!/bin/bash

# Quick setup test script
# Usage: ./test-setup.sh

set -e

echo "🧪 Testing Infoblox Terraform Automation Setup"
echo "=============================================="

# Test 1: Check required tools
echo "✅ Checking required tools..."
command -v terraform >/dev/null 2>&1 || { echo "❌ terraform not found"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ python3 not found"; exit 1; }
echo "✅ Tools check passed"

# Test 2: Check directory structure
echo "✅ Checking directory structure..."
dirs=("environments/dev" "environments/staging" "environments/prod" "modules/ipam" "modules/dns" "scripts" "docs")
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
    "main.tf"
    "variables.tf" 
    "outputs.tf"
    "versions.tf"
    "environments/dev/main.tf"
    "environments/dev/configs/networks.yaml"
    "scripts/deploy.sh"
    "scripts/validate-config.sh"
    "Makefile"
    "README.md"
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
if [ ! -x "scripts/deploy.sh" ]; then
    echo "❌ scripts/deploy.sh is not executable"
    exit 1
fi
if [ ! -x "scripts/validate-config.sh" ]; then
    echo "❌ scripts/validate-config.sh is not executable"
    exit 1
fi
echo "✅ Script permissions check passed"

# Test 5: Validate Terraform syntax
echo "✅ Checking Terraform syntax..."
terraform fmt -check=true -diff=true . || { echo "❌ Terraform formatting issues found. Run 'terraform fmt -recursive .'"; exit 1; }

# Check each environment
for env in dev staging prod; do
    echo "  Checking $env environment..."
    cd "environments/$env"
    terraform init -backend=false >/dev/null 2>&1 || { echo "❌ Terraform init failed for $env"; exit 1; }
    terraform validate >/dev/null 2>&1 || { echo "❌ Terraform validation failed for $env"; exit 1; }
    cd ../..
done
echo "✅ Terraform syntax check passed"

# Test 6: Validate YAML configuration files
echo "✅ Checking YAML configuration files..."
if command -v python3 >/dev/null 2>&1; then
    python3 -c "import yaml" 2>/dev/null || { echo "⚠️  PyYAML not installed - skipping YAML validation"; }
    
    if python3 -c "import yaml" 2>/dev/null; then
        for env in dev staging prod; do
            config_dir="environments/$env/configs"
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

echo ""
echo "🎉 All tests passed! Setup is ready for use."
echo ""
echo "Next steps:"
echo "1. Copy terraform.tfvars.example to terraform.tfvars in each environment"
echo "2. Configure your Infoblox connection details"
echo "3. Customize the YAML configuration files"
echo "4. Run: make validate ENV=dev"
echo "5. Run: make plan ENV=dev"
echo ""
echo "For more information, see docs/getting-started.md"
