#!/bin/bash
"""
Backstage Action: Merge DNS Configuration
Custom action for merging Backstage-generated DNS configurations
"""

set -euo pipefail

# Input parameters from Backstage
ENVIRONMENT="${INPUT_ENVIRONMENT}"
ENTITY_NAME="${INPUT_ENTITY_NAME}"
BACKSTAGE_ID="${INPUT_BACKSTAGE_ID}"
MERGE_STRATEGY="${INPUT_MERGE_STRATEGY:-backstage-wins}"

# Working directory setup
WORKSPACE_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
SCRIPT_DIR="$WORKSPACE_DIR/scripts"

echo "🚀 Backstage DNS Configuration Merge"
echo "Environment: $ENVIRONMENT"
echo "Entity: $ENTITY_NAME"
echo "Backstage ID: $BACKSTAGE_ID"
echo "Strategy: $MERGE_STRATEGY"

# Verify merge script exists
if [[ ! -f "$SCRIPT_DIR/merge-backstage-config.py" ]]; then
    echo "❌ Merge script not found: $SCRIPT_DIR/merge-backstage-config.py"
    exit 1
fi

# Run the merge
echo "📝 Merging configuration files..."
python3 "$SCRIPT_DIR/merge-backstage-config.py" \
    "$ENVIRONMENT" \
    --source-dir "$WORKSPACE_DIR" \
    --strategy "$MERGE_STRATEGY"

# Check if merge was successful
if [[ $? -eq 0 ]]; then
    echo "✅ Configuration merge completed successfully"
    
    # Output results for Backstage
    echo "::set-output name=merge_status::success"
    echo "::set-output name=environment::$ENVIRONMENT"
    echo "::set-output name=entity_name::$ENTITY_NAME"
    echo "::set-output name=backstage_id::$BACKSTAGE_ID"
    
    # Clean up Backstage files from root
    echo "🧹 Cleaning up temporary files..."
    rm -f "$WORKSPACE_DIR"/*-records.yaml
    
else
    echo "❌ Configuration merge failed"
    echo "::set-output name=merge_status::failed"
    exit 1
fi
