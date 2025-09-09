#!/usr/bin/env python3
"""
Backstage Configuration Merge Script
Intelligently merges Backstage-generated configurations into existing environment files
"""

import yaml
import argparse
import sys
import os
import shutil
import re
from datetime import datetime
from typing import Dict, Any, List, Tuple
from pathlib import Path

class BackstageMerger:
    def __init__(self, environment: str, config_path: str = "."):
        self.environment = environment
        self.config_path = Path(config_path)
        self.target_dir = self.config_path / "live" / environment / "configs"
        self.backup_dir = None
        
    def create_backup(self) -> str:
        """Create backup of current configuration files"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.backup_dir = self.config_path / "backups" / f"merge_{timestamp}"
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        # Backup existing configuration files
        config_files = ["a-records.yaml", "cname-records.yaml", "host-records.yaml", 
                       "networks.yaml", "dns-zones.yaml"]
        
        for config_file in config_files:
            src_file = self.target_dir / config_file
            if src_file.exists():
                dst_file = self.backup_dir / config_file
                shutil.copy2(src_file, dst_file)
                print(f"✅ Backed up {config_file}")
        
        return str(self.backup_dir)
    
    def load_yaml_safely(self, file_path: Path) -> Dict[str, Any]:
        """Load YAML file with error handling"""
        try:
            if file_path.exists():
                with open(file_path, 'r') as f:
                    content = f.read()
                    # Remove any environment comments that might cause parsing issues
                    content = re.sub(r'^# Environment:.*$', '', content, flags=re.MULTILINE)
                    return yaml.safe_load(content) or {}
            return {}
        except yaml.YAMLError as e:
            print(f"❌ Error parsing {file_path}: {e}")
            return {}
    
    def save_yaml_with_header(self, data: Dict[str, Any], file_path: Path, 
                             record_type: str, additions: List[str] = None):
        """Save YAML with proper header and formatting"""
        with open(file_path, 'w') as f:
            # Write header
            f.write(f"# {record_type} Records - {self.environment.title()} Environment\n")
            f.write(f"# Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"# Managed by Terraform and Backstage\n")
            
            if additions:
                f.write(f"# Recent additions: {', '.join(additions)}\n")
            
            f.write("\n")
            
            # Write YAML data with proper formatting
            if data:
                yaml.dump(data, f, default_flow_style=False, sort_keys=False, 
                         allow_unicode=True, width=120)
            else:
                f.write("# No records configured\n")
    
    def detect_conflicts(self, existing: Dict[str, Any], new: Dict[str, Any]) -> List[str]:
        """Detect potential merge conflicts"""
        conflicts = []
        
        for key, new_value in new.items():
            if key in existing:
                existing_value = existing[key]
                
                # Check if this is a Backstage-managed resource being updated
                existing_tags = existing_value.get('ea_tags', {})
                new_tags = new_value.get('ea_tags', {})
                
                existing_backstage_id = existing_tags.get('BackstageId')
                new_backstage_id = new_tags.get('BackstageId')
                
                # If both have Backstage IDs and they're different, it's a conflict
                if (existing_backstage_id and new_backstage_id and 
                    existing_backstage_id != new_backstage_id):
                    conflicts.append(f"Resource '{key}': Existing BackstageId '{existing_backstage_id}' "
                                   f"vs New BackstageId '{new_backstage_id}'")
                
                # If existing is manual (no BackstageId) but new is Backstage
                elif not existing_backstage_id and new_backstage_id:
                    conflicts.append(f"Resource '{key}': Attempting to overwrite manual resource "
                                   f"with Backstage resource '{new_backstage_id}'")
        
        return conflicts
    
    def resolve_conflicts(self, existing: Dict[str, Any], new: Dict[str, Any], 
                         strategy: str = "backstage-wins") -> Dict[str, Any]:
        """Resolve merge conflicts based on strategy"""
        merged = existing.copy()
        
        for key, new_value in new.items():
            if key in existing:
                existing_value = existing[key]
                existing_tags = existing_value.get('ea_tags', {})
                new_tags = new_value.get('ea_tags', {})
                
                existing_backstage_id = existing_tags.get('BackstageId')
                new_backstage_id = new_tags.get('BackstageId')
                
                if strategy == "backstage-wins":
                    # Backstage updates always win
                    if new_backstage_id:
                        merged[key] = new_value
                        print(f"🔄 Updated Backstage resource: {key} ({new_backstage_id})")
                
                elif strategy == "manual-protected":
                    # Protect manual resources, allow Backstage updates
                    if not existing_backstage_id and new_backstage_id:
                        print(f"⚠️  Skipping overwrite of manual resource: {key}")
                        # Keep existing
                    else:
                        merged[key] = new_value
                        print(f"🔄 Updated resource: {key}")
                
                elif strategy == "timestamp-wins":
                    # Newer resource wins based on timestamps
                    existing_time = existing_tags.get('CreatedAt', '1970-01-01')
                    new_time = new_tags.get('CreatedAt', '1970-01-01')
                    
                    if new_time >= existing_time:
                        merged[key] = new_value
                        print(f"🔄 Updated resource (newer): {key}")
                    else:
                        print(f"⏭️  Skipped resource (older): {key}")
            else:
                # New resource, add it
                merged[key] = new_value
                backstage_id = new_value.get('ea_tags', {}).get('BackstageId', key)
                print(f"➕ Added new resource: {key} ({backstage_id})")
        
        return merged
    
    def merge_file(self, backstage_file: Path, strategy: str = "backstage-wins") -> bool:
        """Merge a single Backstage file into target environment"""
        # Determine target file
        target_file = self.target_dir / backstage_file.name
        
        # Load both files
        backstage_data = self.load_yaml_safely(backstage_file)
        existing_data = self.load_yaml_safely(target_file)
        
        if not backstage_data:
            print(f"⚠️  No data found in {backstage_file}")
            return False
        
        # Detect conflicts
        conflicts = self.detect_conflicts(existing_data, backstage_data)
        
        if conflicts:
            print(f"⚠️  Conflicts detected in {backstage_file.name}:")
            for conflict in conflicts:
                print(f"   - {conflict}")
            
            if strategy == "fail-on-conflict":
                print(f"❌ Merge failed due to conflicts in {backstage_file.name}")
                return False
        
        # Resolve and merge
        merged_data = self.resolve_conflicts(existing_data, backstage_data, strategy)
        
        # Determine record type for header
        record_types = {
            "a-records.yaml": "A",
            "cname-records.yaml": "CNAME", 
            "host-records.yaml": "Host",
            "networks.yaml": "Network",
            "dns-zones.yaml": "DNS Zone"
        }
        record_type = record_types.get(backstage_file.name, "DNS")
        
        # Track additions
        new_keys = list(backstage_data.keys())
        
        # Save merged file
        self.target_dir.mkdir(parents=True, exist_ok=True)
        self.save_yaml_with_header(merged_data, target_file, record_type, new_keys)
        
        print(f"✅ Merged {len(new_keys)} record(s) into {target_file.name}")
        return True
    
    def merge_all_files(self, source_dir: Path, strategy: str = "backstage-wins") -> Dict[str, bool]:
        """Merge all Backstage files from source directory"""
        backstage_files = [
            "a-records.yaml", "cname-records.yaml", "host-records.yaml",
            "networks.yaml", "dns-zones.yaml"
        ]
        
        results = {}
        
        for file_name in backstage_files:
            source_file = source_dir / file_name
            if source_file.exists():
                results[file_name] = self.merge_file(source_file, strategy)
            else:
                print(f"⏭️  Skipping {file_name} (not found)")
                results[file_name] = None
        
        return results
    
    def generate_merge_report(self, results: Dict[str, bool], backup_path: str) -> str:
        """Generate a merge report"""
        report = f"""
# Backstage Merge Report
**Environment:** {self.environment}
**Timestamp:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Backup Location:** {backup_path}

## Merge Results:
"""
        
        for file_name, result in results.items():
            if result is True:
                report += f"- ✅ {file_name}: Successfully merged\n"
            elif result is False:
                report += f"- ❌ {file_name}: Merge failed\n"
            else:
                report += f"- ⏭️  {file_name}: Skipped (not found)\n"
        
        report += f"""
## Next Steps:
1. Review the merged configurations in `live/{self.environment}/configs/`
2. Run validation: `./scripts/validate-config.sh {self.environment}`
3. Test with Terragrunt plan: `cd live/{self.environment} && terragrunt plan`
4. If issues occur, restore from backup: `{backup_path}`

## Cleanup:
To remove the original Backstage files after verification:
```bash
rm -f *-records.yaml  # Remove root-level Backstage files
```
"""
        
        return report

def main():
    parser = argparse.ArgumentParser(description='Merge Backstage configurations into environment')
    parser.add_argument('environment', help='Target environment (dev/staging/prod)')
    parser.add_argument('--source-dir', '-s', default='.', 
                       help='Directory containing Backstage-generated files')
    parser.add_argument('--strategy', '-t', 
                       choices=['backstage-wins', 'manual-protected', 'timestamp-wins', 'fail-on-conflict'],
                       default='backstage-wins',
                       help='Conflict resolution strategy')
    parser.add_argument('--dry-run', '-d', action='store_true',
                       help='Show what would be done without making changes')
    parser.add_argument('--no-backup', action='store_true',
                       help='Skip creating backup (not recommended)')
    
    args = parser.parse_args()
    
    # Validate environment
    if args.environment not in ['dev', 'staging', 'prod']:
        print("❌ Environment must be one of: dev, staging, prod")
        sys.exit(1)
    
    # Initialize merger
    merger = BackstageMerger(args.environment, args.source_dir)
    
    print(f"🚀 Starting Backstage merge for {args.environment} environment")
    print(f"📁 Source: {args.source_dir}")
    print(f"🎯 Target: {merger.target_dir}")
    print(f"🔧 Strategy: {args.strategy}")
    
    if args.dry_run:
        print("🧪 DRY RUN MODE - No changes will be made")
        # TODO: Implement dry-run logic
        return
    
    # Create backup
    backup_path = ""
    if not args.no_backup:
        backup_path = merger.create_backup()
        print(f"💾 Backup created: {backup_path}")
    
    # Perform merge
    source_dir = Path(args.source_dir)
    results = merger.merge_all_files(source_dir, args.strategy)
    
    # Generate report
    report = merger.generate_merge_report(results, backup_path)
    
    # Save report
    report_file = Path("backstage-merge-report.md")
    with open(report_file, 'w') as f:
        f.write(report)
    
    print(f"\n📊 Merge completed! Report saved to: {report_file}")
    print("\n" + "="*60)
    print(report)

if __name__ == '__main__':
    main()
