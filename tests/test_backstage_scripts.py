#!/usr/bin/env python3
"""
Comprehensive Test Suite for Infoblox Backstage Scripts
Tests both merge-backstage-config.py and manage-backstage-resources.py
"""

import unittest
import tempfile
import shutil
import os
import sys
import yaml
import json
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add the scripts directory to Python path
test_dir = Path(__file__).parent
project_root = test_dir.parent
scripts_dir = project_root / "scripts"
sys.path.insert(0, str(scripts_dir))

# Import the modules we're testing
sys.path.insert(0, str(scripts_dir))

# Import with proper module handling
import importlib.util

# Load merge-backstage-config.py
merge_spec = importlib.util.spec_from_file_location(
    "merge_backstage_config", 
    scripts_dir / "merge-backstage-config.py"
)
merge_module = importlib.util.module_from_spec(merge_spec)
merge_spec.loader.exec_module(merge_module)
BackstageMerger = merge_module.BackstageMerger

# Load manage-backstage-resources.py  
manage_spec = importlib.util.spec_from_file_location(
    "manage_backstage_resources",
    scripts_dir / "manage-backstage-resources.py"
)
manage_module = importlib.util.module_from_spec(manage_spec)
manage_spec.loader.exec_module(manage_module)
InfobloxResourceManager = manage_module.InfobloxResourceManager

class TestBackstageMerger(unittest.TestCase):
    """Test cases for the Backstage configuration merger"""
    
    def setUp(self):
        """Set up test environment before each test"""
        self.test_dir = tempfile.mkdtemp()
        self.test_path = Path(self.test_dir)
        
        # Create test environment structure
        self.env_dir = self.test_path / "environments" / "test-env"
        self.env_dir.mkdir(parents=True)
        
        # Copy test fixtures
        fixtures_dir = test_dir / "fixtures"
        
        # Set up existing environment files
        shutil.copy(fixtures_dir / "existing-a-records.yaml", 
                   self.env_dir / "a-records.yaml")
        shutil.copy(fixtures_dir / "existing-cname-records.yaml", 
                   self.env_dir / "cname-records.yaml")
        
        # Create merger instance
        self.merger = BackstageMerger("test-env", str(self.test_path))
        
        print(f"Test setup complete: {self.test_dir}")
    
    def tearDown(self):
        """Clean up after each test"""
        shutil.rmtree(self.test_dir)
    
    def test_load_yaml_safely(self):
        """Test YAML loading with various formats"""
        # Test normal YAML file
        test_file = self.test_path / "test.yaml"
        with open(test_file, 'w') as f:
            f.write("key: value\nlist:\n  - item1\n  - item2")
        
        data = self.merger.load_yaml_safely(test_file)
        self.assertEqual(data['key'], 'value')
        self.assertEqual(len(data['list']), 2)
        
        # Test non-existent file
        data = self.merger.load_yaml_safely(self.test_path / "nonexistent.yaml")
        self.assertEqual(data, {})
        
        # Test empty file
        empty_file = self.test_path / "empty.yaml"
        open(empty_file, 'w').close()
        data = self.merger.load_yaml_safely(empty_file)
        self.assertEqual(data, {})
    
    def test_detect_conflicts_no_conflicts(self):
        """Test conflict detection with no conflicts"""
        existing = {"resource1": {"fqdn": "test1.com", "ea_tags": {}}}
        new = {"resource2": {"fqdn": "test2.com", "ea_tags": {"BackstageId": "new-123"}}}
        
        conflicts = self.merger.detect_conflicts(existing, new)
        self.assertEqual(len(conflicts), 0)
    
    def test_detect_conflicts_backstage_vs_backstage(self):
        """Test conflict detection between different Backstage resources"""
        existing = {
            "resource1": {
                "fqdn": "test.com",
                "ea_tags": {"BackstageId": "old-app-123", "CreatedBy": "backstage"}
            }
        }
        new = {
            "resource1": {
                "fqdn": "test.com", 
                "ea_tags": {"BackstageId": "new-app-456", "CreatedBy": "backstage"}
            }
        }
        
        conflicts = self.merger.detect_conflicts(existing, new)
        self.assertEqual(len(conflicts), 1)
        self.assertIn("old-app-123", conflicts[0])
        self.assertIn("new-app-456", conflicts[0])
    
    def test_detect_conflicts_manual_vs_backstage(self):
        """Test conflict detection between manual and Backstage resources"""
        existing = {
            "resource1": {
                "fqdn": "test.com",
                "ea_tags": {"Owner": "manual-user"}  # No BackstageId = manual
            }
        }
        new = {
            "resource1": {
                "fqdn": "test.com",
                "ea_tags": {"BackstageId": "new-app-456", "CreatedBy": "backstage"}
            }
        }
        
        conflicts = self.merger.detect_conflicts(existing, new)
        self.assertEqual(len(conflicts), 1)
        self.assertIn("manual resource", conflicts[0])
    
    def test_resolve_conflicts_backstage_wins(self):
        """Test conflict resolution with backstage-wins strategy"""
        existing = {
            "resource1": {"fqdn": "old.com", "ea_tags": {"BackstageId": "old-123"}},
            "resource2": {"fqdn": "manual.com", "ea_tags": {"Owner": "manual"}}
        }
        new = {
            "resource1": {"fqdn": "new.com", "ea_tags": {"BackstageId": "new-456"}},
            "resource3": {"fqdn": "added.com", "ea_tags": {"BackstageId": "added-789"}}
        }
        
        merged = self.merger.resolve_conflicts(existing, new, "backstage-wins")
        
        # Backstage resource should be updated
        self.assertEqual(merged["resource1"]["fqdn"], "new.com")
        self.assertEqual(merged["resource1"]["ea_tags"]["BackstageId"], "new-456")
        
        # Manual resource should remain
        self.assertEqual(merged["resource2"]["fqdn"], "manual.com")
        
        # New resource should be added
        self.assertEqual(merged["resource3"]["fqdn"], "added.com")
    
    def test_resolve_conflicts_manual_protected(self):
        """Test conflict resolution with manual-protected strategy"""
        existing = {
            "manual_resource": {"fqdn": "manual.com", "ea_tags": {"Owner": "manual"}},
            "backstage_resource": {"fqdn": "old-backstage.com", "ea_tags": {"BackstageId": "old-123"}}
        }
        new = {
            "manual_resource": {"fqdn": "new-manual.com", "ea_tags": {"BackstageId": "trying-456"}},
            "backstage_resource": {"fqdn": "new-backstage.com", "ea_tags": {"BackstageId": "old-123"}}
        }
        
        with patch('builtins.print'):  # Suppress print output during test
            merged = self.merger.resolve_conflicts(existing, new, "manual-protected")
        
        # Manual resource should be protected
        self.assertEqual(merged["manual_resource"]["fqdn"], "manual.com")
        self.assertEqual(merged["manual_resource"]["ea_tags"]["Owner"], "manual")
        
        # Backstage resource should be updated
        self.assertEqual(merged["backstage_resource"]["fqdn"], "new-backstage.com")
    
    def test_merge_file_success(self):
        """Test successful file merge"""
        # Create new Backstage file
        fixtures_dir = test_dir / "fixtures"
        backstage_file = self.test_path / "a-records.yaml"
        shutil.copy(fixtures_dir / "new-backstage-a-records.yaml", backstage_file)
        
        # Perform merge
        with patch('builtins.print'):  # Suppress print output
            result = self.merger.merge_file(backstage_file, "backstage-wins")
        
        self.assertTrue(result)
        
        # Check merged file
        merged_file = self.env_dir / "a-records.yaml"
        self.assertTrue(merged_file.exists())
        
        with open(merged_file, 'r') as f:
            merged_data = yaml.safe_load(f)
        
        # Should have original + new resources
        self.assertIn("legacy_web_server", merged_data)  # Original
        self.assertIn("my_app_api", merged_data)  # New
        self.assertIn("my_app_web", merged_data)  # New
        
        # Check Backstage ID is preserved
        self.assertEqual(merged_data["my_app_api"]["ea_tags"]["BackstageId"], 
                        "my-app-test-20250909120000")
    
    def test_merge_file_with_conflicts(self):
        """Test file merge with conflicts"""
        # Create conflicting Backstage file
        fixtures_dir = test_dir / "fixtures"
        backstage_file = self.test_path / "a-records.yaml"
        shutil.copy(fixtures_dir / "conflicting-a-records.yaml", backstage_file)
        
        # Test with fail-on-conflict strategy
        with patch('builtins.print'):  # Suppress print output
            result = self.merger.merge_file(backstage_file, "fail-on-conflict")
        
        self.assertFalse(result)  # Should fail due to conflicts
        
        # Test with backstage-wins strategy
        with patch('builtins.print'):
            result = self.merger.merge_file(backstage_file, "backstage-wins")
        
        self.assertTrue(result)  # Should succeed with conflicts resolved
    
    def test_create_backup(self):
        """Test backup creation"""
        backup_path = self.merger.create_backup()
        
        backup_dir = Path(backup_path)
        self.assertTrue(backup_dir.exists())
        self.assertTrue((backup_dir / "a-records.yaml").exists())
        self.assertTrue((backup_dir / "cname-records.yaml").exists())


class TestInfobloxResourceManager(unittest.TestCase):
    """Test cases for the Infoblox resource manager"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.test_path = Path(self.test_dir)
        
        # Create test configuration files
        fixtures_dir = test_dir / "fixtures"
        shutil.copy(fixtures_dir / "existing-a-records.yaml", 
                   self.test_path / "a-records.yaml")
        shutil.copy(fixtures_dir / "existing-cname-records.yaml", 
                   self.test_path / "cname-records.yaml")
        
        # Create manager instance
        self.manager = InfobloxResourceManager(str(self.test_path))
        
        print(f"Resource manager test setup: {self.test_dir}")
    
    def tearDown(self):
        """Clean up after each test"""
        shutil.rmtree(self.test_dir)
    
    def test_load_configurations(self):
        """Test configuration loading"""
        # Manager should have loaded the test files
        self.assertIsInstance(self.manager.backstage_resources, dict)
        
        # Should find Backstage resources
        backstage_ids = list(self.manager.backstage_resources.keys())
        self.assertIn("old-app-test-20250901120000", backstage_ids)
    
    def test_list_backstage_resources(self):
        """Test listing Backstage resources"""
        resources = self.manager.list_backstage_resources()
        
        # Should return list of resources
        self.assertIsInstance(resources, list)
        self.assertGreater(len(resources), 0)
        
        # Check resource structure
        resource = resources[0]
        required_keys = ['backstage_id', 'entity_name', 'resource_name', 
                        'source_file', 'owner', 'created_at', 'record_type']
        for key in required_keys:
            self.assertIn(key, resource)
    
    def test_list_backstage_resources_with_filter(self):
        """Test listing resources with entity filter"""
        # Filter by entity that exists
        resources = self.manager.list_backstage_resources("old-app")
        self.assertGreater(len(resources), 0)
        
        for resource in resources:
            self.assertIn("old-app", resource.get('entity_name', ''))
        
        # Filter by entity that doesn't exist
        resources = self.manager.list_backstage_resources("nonexistent")
        self.assertEqual(len(resources), 0)
    
    def test_find_resources_by_entity(self):
        """Test finding resources by specific entity"""
        resources = self.manager.find_resources_by_entity("old-app")
        
        self.assertIsInstance(resources, list)
        for resource in resources:
            self.assertEqual(resource['entity_name'], "old-app")
    
    def test_generate_cleanup_config(self):
        """Test cleanup configuration generation"""
        # Get a known Backstage ID
        resources = self.manager.list_backstage_resources()
        if resources:
            backstage_id = resources[0]['backstage_id']
            
            cleanup_config = self.manager.generate_cleanup_config([backstage_id])
            
            self.assertIn('resources_to_remove', cleanup_config)
            self.assertIn('terraform_commands', cleanup_config)
            self.assertEqual(len(cleanup_config['resources_to_remove']), 1)
            
            resource = cleanup_config['resources_to_remove'][0]
            self.assertEqual(resource['backstage_id'], backstage_id)
            self.assertIn('terraform_resource', resource)
    
    def test_validate_backstage_id_format(self):
        """Test Backstage ID format validation"""
        # Valid formats
        valid_ids = [
            "my-app-dev-20250909120000",
            "web-service-prod-20251231235959",
            "api-gateway-staging-20250101000000"
        ]
        
        for backstage_id in valid_ids:
            self.assertTrue(self.manager.validate_backstage_id_format(backstage_id),
                          f"Should be valid: {backstage_id}")
        
        # Invalid formats
        invalid_ids = [
            "my-app-dev",  # Missing timestamp
            "my-app-dev-2025090912000",  # Wrong timestamp format
            "MyApp-dev-20250909120000",  # Uppercase
            "my_app-dev-20250909120000",  # Underscore
            "my-app-invalid-20250909120000",  # Invalid environment
        ]
        
        for backstage_id in invalid_ids:
            self.assertFalse(self.manager.validate_backstage_id_format(backstage_id),
                           f"Should be invalid: {backstage_id}")
    
    def test_get_record_type(self):
        """Test record type detection"""
        # A record
        a_config = {"fqdn": "test.com", "ip_addr": "10.1.1.1"}
        self.assertEqual(self.manager._get_record_type(a_config), "A")
        
        # HOST record (with allocation)
        host_config = {"fqdn": "test.com", "ip_addr": "10.1.1.1", "allocate_ip": True}
        self.assertEqual(self.manager._get_record_type(host_config), "HOST")
        
        # CNAME record
        cname_config = {"alias": "www.test.com", "canonical": "test.com"}
        self.assertEqual(self.manager._get_record_type(cname_config), "CNAME")
        
        # Network
        network_config = {"network": "10.1.0.0/24"}
        self.assertEqual(self.manager._get_record_type(network_config), "NETWORK")
        
        # Unknown
        unknown_config = {"some_field": "value"}
        self.assertEqual(self.manager._get_record_type(unknown_config), "UNKNOWN")


class TestIntegration(unittest.TestCase):
    """Integration tests for complete workflows"""
    
    def setUp(self):
        """Set up integration test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.test_path = Path(self.test_dir)
        
        # Create full environment structure
        self.env_dir = self.test_path / "environments" / "test-env"
        self.env_dir.mkdir(parents=True)
        
        fixtures_dir = test_dir / "fixtures"
        
        # Set up existing files
        shutil.copy(fixtures_dir / "existing-a-records.yaml", 
                   self.env_dir / "a-records.yaml")
        shutil.copy(fixtures_dir / "existing-cname-records.yaml", 
                   self.env_dir / "cname-records.yaml")
        
        print(f"Integration test setup: {self.test_dir}")
    
    def tearDown(self):
        """Clean up after integration tests"""
        shutil.rmtree(self.test_dir)
    
    def test_full_merge_and_cleanup_workflow(self):
        """Test complete merge -> manage -> cleanup workflow"""
        fixtures_dir = test_dir / "fixtures"
        
        # Step 1: Merge new Backstage configurations
        merger = BackstageMerger("test-env", str(self.test_path))
        
        # Copy new Backstage files to root
        backstage_a_file = self.test_path / "a-records.yaml"
        backstage_cname_file = self.test_path / "cname-records.yaml"
        
        shutil.copy(fixtures_dir / "new-backstage-a-records.yaml", backstage_a_file)
        shutil.copy(fixtures_dir / "new-backstage-cname-records.yaml", backstage_cname_file)
        
        # Perform merge
        with patch('builtins.print'):
            merge_results = merger.merge_all_files(self.test_path, "backstage-wins")
        
        self.assertTrue(merge_results["a-records.yaml"])
        self.assertTrue(merge_results["cname-records.yaml"])
        
        # Step 2: Use resource manager to find the merged resources
        manager = InfobloxResourceManager(str(self.env_dir))
        
        resources = manager.list_backstage_resources()
        my_app_resources = manager.find_resources_by_entity("my-app")
        
        # Should find the newly merged resources
        self.assertGreater(len(my_app_resources), 0)
        
        # Should find both A and CNAME records for my-app
        record_types = [r['record_type'] for r in my_app_resources]
        self.assertIn("A", record_types)
        self.assertIn("CNAME", record_types)
        
        # Step 3: Generate cleanup configuration
        my_app_ids = [r['backstage_id'] for r in my_app_resources]
        cleanup_config = manager.generate_cleanup_config(my_app_ids)
        
        self.assertEqual(len(cleanup_config['resources_to_remove']), len(my_app_resources))
        
        # Verify terraform resource names are generated correctly
        for resource in cleanup_config['resources_to_remove']:
            self.assertIn('terraform_resource', resource)
            terraform_resource = resource['terraform_resource']
            
            if resource['source_file'] == 'a-records.yaml':
                self.assertTrue(terraform_resource.startswith('infoblox_a_record.'))
            elif resource['source_file'] == 'cname-records.yaml':
                self.assertTrue(terraform_resource.startswith('infoblox_cname_record.'))
        
        print(f"✅ Integration test completed successfully")
        print(f"   - Merged {len(merge_results)} file types")
        print(f"   - Found {len(my_app_resources)} my-app resources")
        print(f"   - Generated cleanup for {len(cleanup_config['resources_to_remove'])} resources")


def run_test_suite():
    """Run the complete test suite"""
    print("🧪 Starting Infoblox Backstage Scripts Test Suite")
    print("=" * 60)
    
    # Create test suite
    suite = unittest.TestSuite()
    
    # Add test cases
    suite.addTest(unittest.makeSuite(TestBackstageMerger))
    suite.addTest(unittest.makeSuite(TestInfobloxResourceManager))
    suite.addTest(unittest.makeSuite(TestIntegration))
    
    # Run tests with detailed output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Print summary
    print("\n" + "=" * 60)
    print("🎯 Test Summary:")
    print(f"   Tests Run: {result.testsRun}")
    print(f"   Failures: {len(result.failures)}")
    print(f"   Errors: {len(result.errors)}")
    
    if result.failures:
        print("\n❌ Failures:")
        for test, traceback in result.failures:
            print(f"   - {test}: {traceback.split('AssertionError:')[-1].strip()}")
    
    if result.errors:
        print("\n💥 Errors:")
        for test, traceback in result.errors:
            print(f"   - {test}: {traceback.split('Error:')[-1].strip()}")
    
    if result.wasSuccessful():
        print("\n✅ All tests passed!")
    else:
        print("\n❌ Some tests failed!")
    
    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_test_suite()
    sys.exit(0 if success else 1)
