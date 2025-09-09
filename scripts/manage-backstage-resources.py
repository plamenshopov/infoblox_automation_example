#!/usr/bin/env python3
"""
Infoblox Resource Management Script
Manages Backstage-created resources with unique identifiers
"""

import argparse
import yaml
import re
import sys
from typing import Dict, List, Any
from pathlib import Path

class InfobloxResourceManager:
    def __init__(self, config_path: str = "."):
        self.config_path = Path(config_path)
        self.backstage_resources = {}
        self._load_configurations()
    
    def _load_configurations(self):
        """Load all YAML configuration files and identify Backstage resources"""
        config_files = [
            "a-records.yaml",
            "cname-records.yaml", 
            "host-records.yaml",
            "networks.yaml",
            "dns-zones.yaml"
        ]
        
        for config_file in config_files:
            file_path = self.config_path / config_file
            if file_path.exists():
                with open(file_path, 'r') as f:
                    data = yaml.safe_load(f) or {}
                    self._extract_backstage_resources(data, config_file)
    
    def _extract_backstage_resources(self, data: Dict, source_file: str):
        """Extract resources created by Backstage based on tags"""
        for resource_name, resource_config in data.items():
            if isinstance(resource_config, dict):
                ea_tags = resource_config.get('ea_tags', {})
                
                # Check if resource was created by Backstage
                if ea_tags.get('CreatedBy') == 'backstage':
                    backstage_id = ea_tags.get('BackstageId')
                    entity_name = ea_tags.get('BackstageEntity')
                    
                    if backstage_id:
                        self.backstage_resources[backstage_id] = {
                            'resource_name': resource_name,
                            'entity_name': entity_name,
                            'source_file': source_file,
                            'config': resource_config,
                            'created_at': ea_tags.get('CreatedAt'),
                            'owner': ea_tags.get('Owner')
                        }
    
    def list_backstage_resources(self, entity_filter: str = None) -> List[Dict]:
        """List all Backstage-created resources, optionally filtered by entity"""
        resources = []
        
        for backstage_id, resource_info in self.backstage_resources.items():
            if entity_filter and entity_filter not in resource_info.get('entity_name', ''):
                continue
                
            resources.append({
                'backstage_id': backstage_id,
                'entity_name': resource_info.get('entity_name'),
                'resource_name': resource_info.get('resource_name'),
                'source_file': resource_info.get('source_file'),
                'owner': resource_info.get('owner'),
                'created_at': resource_info.get('created_at'),
                'record_type': self._get_record_type(resource_info.get('config', {}))
            })
        
        return sorted(resources, key=lambda x: x['created_at'] or '')
    
    def _get_record_type(self, config: Dict) -> str:
        """Determine record type from configuration"""
        if 'ip_addr' in config and 'fqdn' in config:
            if config.get('allocate_ip'):
                return 'HOST'
            else:
                return 'A'
        elif 'alias' in config and 'canonical' in config:
            return 'CNAME'
        elif 'network' in config:
            return 'NETWORK'
        else:
            return 'UNKNOWN'
    
    def find_resources_by_entity(self, entity_name: str) -> List[Dict]:
        """Find all resources for a specific Backstage entity"""
        return [
            resource for resource in self.list_backstage_resources()
            if resource['entity_name'] == entity_name
        ]
    
    def generate_cleanup_config(self, backstage_ids: List[str]) -> Dict[str, Any]:
        """Generate configuration for cleaning up specific resources"""
        cleanup_config = {
            'resources_to_remove': [],
            'terraform_commands': []
        }
        
        for backstage_id in backstage_ids:
            if backstage_id in self.backstage_resources:
                resource_info = self.backstage_resources[backstage_id]
                cleanup_config['resources_to_remove'].append({
                    'backstage_id': backstage_id,
                    'resource_name': resource_info['resource_name'],
                    'source_file': resource_info['source_file'],
                    'terraform_resource': self._get_terraform_resource_name(
                        resource_info['source_file'], 
                        resource_info['resource_name']
                    )
                })
        
        return cleanup_config
    
    def _get_terraform_resource_name(self, source_file: str, resource_name: str) -> str:
        """Generate Terraform resource name for targeting"""
        resource_type_map = {
            'a-records.yaml': 'infoblox_a_record',
            'cname-records.yaml': 'infoblox_cname_record',
            'host-records.yaml': 'infoblox_host_record',
            'networks.yaml': 'infoblox_network',
            'dns-zones.yaml': 'infoblox_zone_auth'
        }
        
        resource_type = resource_type_map.get(source_file, 'unknown')
        return f"{resource_type}.{resource_name}"
    
    def validate_backstage_id_format(self, backstage_id: str) -> bool:
        """Validate Backstage ID format"""
        # Expected format: entity-environment-timestamp
        pattern = r'^[a-z0-9-]+-(?:dev|staging|prod)-\d{14}$'
        return bool(re.match(pattern, backstage_id))

    def remove_backstage_resource(self, backstage_id: str) -> bool:
        """Remove a Backstage resource from configuration files"""
        if backstage_id not in self.backstage_resources:
            print(f"❌ Resource with ID '{backstage_id}' not found")
            return False
        
        resource_info = self.backstage_resources[backstage_id]
        source_file = resource_info['source_file']
        resource_name = resource_info['resource_name']
        
        file_path = self.config_path / source_file
        
        # Load the file
        with open(file_path, 'r') as f:
            data = yaml.safe_load(f) or {}
        
        # Remove the resource
        if resource_name in data:
            del data[resource_name]
            
            # Write back to file
            with open(file_path, 'w') as f:
                yaml.dump(data, f, default_flow_style=False, sort_keys=False)
            
            print(f"✅ Removed resource '{resource_name}' from {source_file}")
            return True
        else:
            print(f"❌ Resource '{resource_name}' not found in {source_file}")
            return False

def main():
    parser = argparse.ArgumentParser(description='Manage Infoblox resources created by Backstage')
    parser.add_argument('--config-path', '-p', default='.', 
                       help='Path to configuration files directory')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List Backstage-created resources')
    list_parser.add_argument('--entity', '-e', help='Filter by entity name')
    list_parser.add_argument('--format', '-f', choices=['table', 'json', 'yaml'], 
                           default='table', help='Output format')
    
    # Find command
    find_parser = subparsers.add_parser('find', help='Find resources by entity')
    find_parser.add_argument('entity_name', help='Entity name to search for')
    find_parser.add_argument('--format', '-f', choices=['table', 'json'], 
                           default='table', help='Output format')
    
    # Cleanup command
    cleanup_parser = subparsers.add_parser('cleanup', help='Generate cleanup configuration')
    cleanup_parser.add_argument('backstage_ids', nargs='+', help='Backstage IDs to clean up')
    cleanup_parser.add_argument('--output', '-o', help='Output file for cleanup config')
    cleanup_parser.add_argument('--dry-run', action='store_true', help='Show what would be removed without doing it')
    cleanup_parser.add_argument('--quiet', action='store_true', help='Minimal output')
    
    # Remove command
    remove_parser = subparsers.add_parser('remove', help='Remove resource from configuration')
    remove_parser.add_argument('backstage_id', help='Backstage ID to remove')
    
    # Validate command
    validate_parser = subparsers.add_parser('validate', help='Validate Backstage ID format')
    validate_parser.add_argument('backstage_id', help='Backstage ID to validate')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    manager = InfobloxResourceManager(args.config_path)
    
    if args.command == 'list':
        resources = manager.list_backstage_resources(args.entity)
        
        if args.format == 'table':
            print(f"{'Backstage ID':<40} {'Entity':<20} {'Resource':<30} {'Type':<10} {'Owner':<15}")
            print("-" * 120)
            for resource in resources:
                print(f"{resource['backstage_id']:<40} {resource['entity_name']:<20} "
                     f"{resource['resource_name']:<30} {resource['record_type']:<10} "
                     f"{resource['owner']:<15}")
        elif args.format == 'json':
            import json
            print(json.dumps(resources, indent=2))
        elif args.format == 'yaml':
            print(yaml.dump(resources, default_flow_style=False))
    
    elif args.command == 'find':
        resources = manager.find_resources_by_entity(args.entity_name)
        
        if args.format == 'json':
            import json
            print(json.dumps(resources, indent=2))
        else:
            print(f"Resources for entity '{args.entity_name}':")
            for resource in resources:
                print(f"  - {resource['backstage_id']} ({resource['record_type']})")
    
    elif args.command == 'cleanup':
        cleanup_config = manager.generate_cleanup_config(args.backstage_ids)
        
        if args.dry_run:
            print("🔍 Dry run - showing what would be removed:")
            print(yaml.dump(cleanup_config, default_flow_style=False))
        elif args.output:
            with open(args.output, 'w') as f:
                yaml.dump(cleanup_config, f, default_flow_style=False)
            print(f"Cleanup configuration written to {args.output}")
        else:
            print(yaml.dump(cleanup_config, default_flow_style=False))
    
    elif args.command == 'remove':
        success = manager.remove_backstage_resource(args.backstage_id)
        if not success:
            sys.exit(1)
    
    elif args.command == 'validate':
        is_valid = manager.validate_backstage_id_format(args.backstage_id)
        if is_valid:
            print(f"✅ Valid Backstage ID format: {args.backstage_id}")
        else:
            print(f"❌ Invalid Backstage ID format: {args.backstage_id}")
            print("Expected format: entity-environment-timestamp (e.g., my-app-dev-20250909120000)")
            sys.exit(1)

if __name__ == '__main__':
    main()
