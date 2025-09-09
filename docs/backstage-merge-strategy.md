# Backstage Configuration Management: Best Practices

## 🎯 **Recommended Approach: Smart Merge Strategy**

After extensive analysis, **Option 1 (Merge Script)** is the optimal solution for your Infoblox automation. Here's why and how to implement it effectively.

## 📊 **Analysis Summary**

### **Option 1: Merge Script ✅ RECOMMENDED**
- **Performance**: Single files = faster Terraform processing
- **State Management**: Cleaner, more manageable Terraform state
- **Compatibility**: Works with existing structure
- **Cleanup**: Your cleanup scripts work perfectly
- **File Management**: Reasonable number of files to maintain

### **Option 2: Separate Files ❌ NOT RECOMMENDED**
- **File Explosion**: Could create hundreds/thousands of files
- **Performance Impact**: Many small files slow down Terraform
- **Complex Management**: Difficult to backup, restore, and navigate
- **State Fragmentation**: Scattered Terraform state management

## 🛠️ **Implementation: Enhanced Merge System**

### **1. Intelligent Merge Script**

The `merge-backstage-config.py` script provides:

```bash
# Basic merge
./scripts/merge-backstage-config.py dev

# Custom strategy
./scripts/merge-backstage-config.py dev --strategy manual-protected

# Dry run first
./scripts/merge-backstage-config.py dev --dry-run
```

### **2. Conflict Resolution Strategies**

#### **A. backstage-wins (Default)**
- Backstage resources always override existing
- Best for full automation scenarios
- Protects against configuration drift

#### **B. manual-protected**
- Protects manually created resources
- Allows Backstage updates only for Backstage-created resources
- Best for mixed manual/automated environments

#### **C. timestamp-wins**
- Newer resources win based on creation timestamp
- Good for collaborative environments

#### **D. fail-on-conflict**
- Stops merge on any conflict
- Forces manual resolution
- Safest but requires more intervention

### **3. Automated GitHub Actions Integration**

```yaml
# In your Backstage template PR
- name: Merge Backstage Configuration
  uses: ./.github/actions/merge-dns-config
  with:
    environment: dev
    entity_name: my-app
    backstage_id: my-app-dev-20250909120000
    merge_strategy: backstage-wins
```

## 📁 **File Structure Impact**

### **Before (Manual)**
```
environments/dev/
├── a-records.yaml        (5-10 records each)
├── cname-records.yaml
├── host-records.yaml
├── networks.yaml
└── dns-zones.yaml
```

### **After (With Backstage + Cleanup)**
```
environments/dev/
├── a-records.yaml        (10-50 records each)
├── cname-records.yaml    (managed automatically)
├── host-records.yaml     (tagged by source)
├── networks.yaml
└── dns-zones.yaml

backups/merge_20250909_120000/  (automatic backups)
├── a-records.yaml.bak
└── ...
```

## 🔄 **Complete Workflow**

### **Step 1: User Creates Resource in Backstage**
```
User fills form:
- Entity: "my-app"
- Environment: "dev"  
- Record: "api.my-app.example.com"
```

### **Step 2: Backstage Generates Configuration**
```yaml
# Generated: a-records.yaml (in PR root)
my_app_api:
  fqdn: "api.my-app.example.com"
  ip_addr: "10.1.1.100"
  comment: "API endpoint | Backstage ID: my-app-dev-20250909120000"
  ea_tags:
    BackstageId: "my-app-dev-20250909120000"
    BackstageEntity: "my-app"
    CreatedBy: "backstage"
```

### **Step 3: Automated Merge Process**
```bash
# GitHub Action automatically:
1. Detects Backstage PR
2. Extracts environment and entity info
3. Runs merge script with conflict resolution
4. Creates backup of existing files
5. Merges into environments/dev/a-records.yaml
6. Removes temporary files
7. Commits changes
```

### **Step 4: Result**
```yaml
# environments/dev/a-records.yaml
# A Records - Dev Environment
# Last updated: 2025-09-09 12:00:00
# Recent additions: my_app_api

existing_manual_record:
  fqdn: "legacy.example.com"
  ip_addr: "10.1.1.50"
  # No BackstageId = manual resource

my_app_api:
  fqdn: "api.my-app.example.com"
  ip_addr: "10.1.1.100"
  comment: "API endpoint | Backstage ID: my-app-dev-20250909120000"
  ea_tags:
    BackstageId: "my-app-dev-20250909120000"
    BackstageEntity: "my-app"
    CreatedBy: "backstage"
```

## 🧹 **Cleanup Integration**

Your existing cleanup script works perfectly:

```bash
# Remove all resources for an entity
./scripts/cleanup-backstage-resources.sh -e dev -n my-app

# The script will:
1. Find all resources with BackstageEntity: "my-app"
2. Generate Terraform destroy targets
3. Remove from YAML files
4. Execute terraform destroy
5. Leave manual resources untouched
```

## 📊 **Performance Comparison**

### **Merge Approach (Recommended)**
```
Environment: dev
Files: 5 YAML files
Terraform resources: ~50-200 per file
State size: Manageable
Plan time: ~10-30 seconds
Apply time: ~30-60 seconds
```

### **Separate Files Approach (Not Recommended)**
```
Environment: dev  
Files: 200+ individual YAML files
Terraform resources: 1-5 per file
State size: Fragmented across many files
Plan time: ~60-120 seconds
Apply time: ~120-300 seconds
```

## 🔧 **Advanced Features**

### **1. Backup and Recovery**
```bash
# Automatic backups before every merge
backups/merge_20250909_120000/
├── a-records.yaml.bak
├── merge-metadata.json
└── restore.sh

# Easy restore
./backups/merge_20250909_120000/restore.sh
```

### **2. Conflict Detection**
```bash
# Preview conflicts before merge
./scripts/merge-backstage-config.py dev --dry-run

# Output:
⚠️  Conflicts detected in a-records.yaml:
   - Resource 'web_server': Existing BackstageId 'old-app-dev-20250901120000' 
     vs New BackstageId 'my-app-dev-20250909120000'
```

### **3. Merge Reports**
```markdown
# Backstage Merge Report
**Environment:** dev
**Timestamp:** 2025-09-09 12:00:00

## Merge Results:
- ✅ a-records.yaml: Successfully merged (2 records)
- ✅ cname-records.yaml: Successfully merged (1 record)
- ⏭️  host-records.yaml: Skipped (not found)
```

## 🎯 **Why This is the Best Approach**

1. ✅ **Terraform Optimized**: Single files = better performance
2. ✅ **State Management**: Cleaner state files
3. ✅ **Backup Safety**: Automatic backups before changes
4. ✅ **Conflict Resolution**: Smart handling of manual vs automated
5. ✅ **Cleanup Compatible**: Works with your existing cleanup scripts
6. ✅ **Scalable**: Handles growth from 10 to 1000+ resources
7. ✅ **Maintainable**: Reasonable number of files to manage
8. ✅ **Automated**: Full GitHub Actions integration

This approach gives you the best of both worlds: powerful automation through Backstage while maintaining the ability to manually manage resources when needed, all within a structure that performs well and scales effectively.
