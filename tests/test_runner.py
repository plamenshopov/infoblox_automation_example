#!/usr/bin/env python3
"""
Simple Test Runner for Backstage Scripts
Tests the core functionality without complex imports
"""

import os
import sys
import tempfile
import shutil
import yaml
import subprocess
from pathlib import Path

# Get project paths
test_dir = Path(__file__).parent
project_root = test_dir.parent
scripts_dir = project_root / "scripts"

class TestRunner:
    def __init__(self):
        self.test_dir = None
        self.passed = 0
        self.failed = 0
        
    def setup_test_env(self):
        """Create temporary test environment"""
        self.test_dir = Path(tempfile.mkdtemp())
        print(f"📁 Test environment: {self.test_dir}")
        
        # Create environment structure
        env_dir = self.test_dir / "environments" / "test-env"
        env_dir.mkdir(parents=True)
        
        # Copy fixtures
        fixtures_dir = test_dir / "fixtures"
        if fixtures_dir.exists():
            shutil.copy(fixtures_dir / "existing-a-records.yaml", 
                       env_dir / "a-records.yaml")
            shutil.copy(fixtures_dir / "existing-cname-records.yaml", 
                       env_dir / "cname-records.yaml")
        
        return env_dir
    
    def cleanup_test_env(self):
        """Clean up test environment"""
        if self.test_dir and self.test_dir.exists():
            shutil.rmtree(self.test_dir)
    
    def assert_true(self, condition, message):
        """Simple assertion helper"""
        if condition:
            print(f"  ✅ {message}")
            self.passed += 1
        else:
            print(f"  ❌ {message}")
            self.failed += 1
    
    def assert_equal(self, actual, expected, message):
        """Equality assertion helper"""
        if actual == expected:
            print(f"  ✅ {message}")
            self.passed += 1
        else:
            print(f"  ❌ {message} - Expected: {expected}, Got: {actual}")
            self.failed += 1
    
    def test_merge_script_basic(self):
        """Test merge script basic functionality"""
        print("\n🧪 Testing merge-backstage-config.py basic functionality")
        
        env_dir = self.setup_test_env()
        
        try:
            # Create a simple Backstage file to merge
            backstage_file = self.test_dir / "a-records.yaml"
            backstage_data = {
                "test_resource": {
                    "fqdn": "test.example.com",
                    "ip_addr": "10.1.1.1",
                    "comment": "Test resource | Backstage ID: test-app-test-20250909120000",
                    "ea_tags": {
                        "BackstageId": "test-app-test-20250909120000",
                        "BackstageEntity": "test-app",
                        "CreatedBy": "backstage"
                    }
                }
            }
            
            with open(backstage_file, 'w') as f:
                yaml.dump(backstage_data, f)
            
            # Test the merge script
            cmd = [
                sys.executable,
                str(scripts_dir / "merge-backstage-config.py"),
                "test-env",
                "--source-dir", str(self.test_dir),
                "--strategy", "backstage-wins"
            ]
            
            print(f"Running: {' '.join(cmd)}")
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.test_dir))
            
            self.assert_equal(result.returncode, 0, "Merge script executed successfully")
            
            # Check if merge was successful
            merged_file = env_dir / "a-records.yaml"
            self.assert_true(merged_file.exists(), "Merged file exists")
            
            if merged_file.exists():
                with open(merged_file, 'r') as f:
                    merged_data = yaml.safe_load(f)
                
                self.assert_true("test_resource" in merged_data, "New resource was merged")
                self.assert_true("legacy_web_server" in merged_data, "Existing resource preserved")
                
                if "test_resource" in merged_data:
                    backstage_id = merged_data["test_resource"]["ea_tags"].get("BackstageId")
                    self.assert_equal(backstage_id, "test-app-test-20250909120000", 
                                    "Backstage ID preserved in merge")
            
            # Check if backup was created
            backup_files = list(self.test_dir.glob("backups/*/"))
            self.assert_true(len(backup_files) > 0, "Backup directory created")
            
        except Exception as e:
            print(f"  ❌ Test failed with exception: {e}")
            self.failed += 1
        finally:
            self.cleanup_test_env()
    
    def test_manage_script_basic(self):
        """Test manage-backstage-resources.py basic functionality"""
        print("\n🧪 Testing manage-backstage-resources.py basic functionality")
        
        env_dir = self.setup_test_env()
        
        try:
            # Test list command
            cmd = [
                sys.executable,
                str(scripts_dir / "manage-backstage-resources.py"),
                "--config-path", str(env_dir),
                "list",
                "--format", "json"
            ]
            
            print(f"Running: {' '.join(cmd)}")
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            self.assert_equal(result.returncode, 0, "List command executed successfully")
            
            if result.returncode == 0:
                try:
                    resources = yaml.safe_load(result.stdout)
                    self.assert_true(isinstance(resources, list), "List command returns array")
                    
                    # Should find the existing Backstage resource from fixtures
                    backstage_resources = [r for r in resources if r.get('backstage_id')]
                    self.assert_true(len(backstage_resources) > 0, "Found Backstage resources in fixtures")
                    
                    if backstage_resources:
                        resource = backstage_resources[0]
                        required_fields = ['backstage_id', 'entity_name', 'resource_name', 'record_type']
                        for field in required_fields:
                            self.assert_true(field in resource, f"Resource has {field} field")
                
                except Exception as e:
                    print(f"  ❌ Failed to parse list output: {e}")
                    self.failed += 1
            
            # Test validate command with valid ID
            cmd = [
                sys.executable,
                str(scripts_dir / "manage-backstage-resources.py"),
                "validate",
                "test-app-dev-20250909120000"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            self.assert_equal(result.returncode, 0, "Valid Backstage ID validation passed")
            
            # Test validate command with invalid ID
            cmd = [
                sys.executable,
                str(scripts_dir / "manage-backstage-resources.py"),
                "validate",
                "invalid-id-format"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            self.assert_equal(result.returncode, 1, "Invalid Backstage ID validation failed correctly")
            
        except Exception as e:
            print(f"  ❌ Test failed with exception: {e}")
            self.failed += 1
        finally:
            self.cleanup_test_env()
    
    def test_integration_workflow(self):
        """Test complete workflow integration"""
        print("\n🧪 Testing integration workflow")
        
        env_dir = self.setup_test_env()
        
        try:
            # Step 1: Create and merge a new Backstage resource
            backstage_file = self.test_dir / "a-records.yaml"
            backstage_data = {
                "integration_test": {
                    "fqdn": "integration.example.com",
                    "ip_addr": "10.1.1.99",
                    "comment": "Integration test | Backstage ID: integration-test-test-20250909120000",
                    "ea_tags": {
                        "BackstageId": "integration-test-test-20250909120000",
                        "BackstageEntity": "integration-test",
                        "CreatedBy": "backstage",
                        "Owner": "test-team"
                    }
                }
            }
            
            with open(backstage_file, 'w') as f:
                yaml.dump(backstage_data, f)
            
            # Merge the resource
            merge_cmd = [
                sys.executable,
                str(scripts_dir / "merge-backstage-config.py"),
                "test-env",
                "--source-dir", str(self.test_dir),
                "--strategy", "backstage-wins"
            ]
            
            merge_result = subprocess.run(merge_cmd, capture_output=True, text=True, cwd=str(self.test_dir))
            self.assert_equal(merge_result.returncode, 0, "Integration merge step succeeded")
            
            # Step 2: Find the merged resource using manage script
            list_cmd = [
                sys.executable,
                str(scripts_dir / "manage-backstage-resources.py"),
                "--config-path", str(env_dir),
                "find",
                "integration-test"
            ]
            
            list_result = subprocess.run(list_cmd, capture_output=True, text=True)
            self.assert_equal(list_result.returncode, 0, "Integration find step succeeded")
            
            # Should find our integration test resource
            self.assert_true("integration-test-test-20250909120000" in list_result.stdout,
                           "Found integration test resource after merge")
            
            # Step 3: Generate cleanup configuration
            cleanup_cmd = [
                sys.executable,
                str(scripts_dir / "manage-backstage-resources.py"),
                "--config-path", str(env_dir),
                "cleanup",
                "integration-test-test-20250909120000"
            ]
            
            cleanup_result = subprocess.run(cleanup_cmd, capture_output=True, text=True)
            self.assert_equal(cleanup_result.returncode, 0, "Integration cleanup config step succeeded")
            
            # Verify cleanup config contains terraform resources
            if cleanup_result.returncode == 0:
                cleanup_config = yaml.safe_load(cleanup_result.stdout)
                self.assert_true("resources_to_remove" in cleanup_config, "Cleanup config has resources")
                self.assert_true(len(cleanup_config["resources_to_remove"]) > 0, "Has resources to remove")
                
                resource = cleanup_config["resources_to_remove"][0]
                self.assert_true("terraform_resource" in resource, "Has terraform resource name")
                self.assert_true(resource["terraform_resource"].startswith("infoblox_"), "Correct terraform resource format")
            
        except Exception as e:
            print(f"  ❌ Integration test failed with exception: {e}")
            self.failed += 1
        finally:
            self.cleanup_test_env()
    
    def test_yaml_fixtures(self):
        """Test that our test fixtures are valid"""
        print("\n🧪 Testing YAML fixtures validity")
        
        fixtures_dir = test_dir / "fixtures"
        
        if not fixtures_dir.exists():
            print(f"  ❌ Fixtures directory not found: {fixtures_dir}")
            self.failed += 1
            return
        
        yaml_files = list(fixtures_dir.glob("*.yaml"))
        self.assert_true(len(yaml_files) > 0, "Found YAML fixture files")
        
        for yaml_file in yaml_files:
            try:
                with open(yaml_file, 'r') as f:
                    data = yaml.safe_load(f)
                self.assert_true(data is not None, f"Valid YAML: {yaml_file.name}")
                
                # Check for required structure in Backstage resources
                if "backstage" in yaml_file.name:
                    for resource_name, resource_config in data.items():
                        if isinstance(resource_config, dict):
                            ea_tags = resource_config.get('ea_tags', {})
                            if ea_tags.get('CreatedBy') == 'backstage':
                                self.assert_true('BackstageId' in ea_tags, 
                                               f"Backstage resource {resource_name} has BackstageId")
                                self.assert_true('BackstageEntity' in ea_tags,
                                               f"Backstage resource {resource_name} has BackstageEntity")
                
            except yaml.YAMLError as e:
                print(f"  ❌ Invalid YAML in {yaml_file.name}: {e}")
                self.failed += 1
            except Exception as e:
                print(f"  ❌ Error processing {yaml_file.name}: {e}")
                self.failed += 1
    
    def run_all_tests(self):
        """Run all tests"""
        print("🚀 Starting Backstage Scripts Test Suite")
        print("=" * 60)
        
        # Run tests
        self.test_yaml_fixtures()
        self.test_merge_script_basic()
        self.test_manage_script_basic()
        self.test_integration_workflow()
        
        # Print summary
        print("\n" + "=" * 60)
        print("🎯 Test Results Summary:")
        print(f"   ✅ Passed: {self.passed}")
        print(f"   ❌ Failed: {self.failed}")
        print(f"   📊 Total:  {self.passed + self.failed}")
        
        if self.failed == 0:
            print("\n🎉 All tests passed! Your scripts are working correctly.")
            return True
        else:
            print(f"\n⚠️  {self.failed} test(s) failed. Please check the output above.")
            return False


if __name__ == '__main__':
    runner = TestRunner()
    success = runner.run_all_tests()
    sys.exit(0 if success else 1)
