# Infoblox Terraform Automation Makefile

.PHONY: help validate plan apply destroy clean format lint check-deps tg-help tg-plan tg-apply tg-destroy

# Default environment
ENV ?= dev

# Colors for output
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

help: ## Show this help message
	@echo "$(BLUE)Infoblox Terraform Automation$(NC)"
	@echo "Usage: make [target] ENV=[environment]"
	@echo ""
	@echo "$(YELLOW)Standard Terraform targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && !/^tg-/ {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Terragrunt targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^tg-[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Available environments: dev, staging, prod"
	@echo "Example: make plan ENV=dev"
	@echo "Example: make tg-plan ENV=staging"

check-deps: ## Check if required dependencies are installed
	@echo "$(BLUE)Checking dependencies...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)Error: terraform is not installed$(NC)"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "$(RED)Error: python3 is not installed$(NC)"; exit 1; }
	@python3 -c "import yaml" 2>/dev/null || { echo "$(RED)Error: PyYAML is not installed. Run: pip install PyYAML$(NC)"; exit 1; }
	@echo "$(GREEN)All dependencies are installed$(NC)"

check-terragrunt: ## Check if Terragrunt is installed
	@command -v terragrunt >/dev/null 2>&1 || { echo "$(RED)Error: terragrunt is not installed$(NC)"; echo "$(YELLOW)Install from: https://terragrunt.gruntwork.io/docs/getting-started/install/$(NC)"; exit 1; }
	@echo "$(GREEN)Terragrunt is installed$(NC)"

validate: check-deps ## Validate configuration for specified environment
	@echo "$(BLUE)Validating configuration for $(ENV) environment...$(NC)"
	@./scripts/validate-config.sh $(ENV)

format: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive .
	@echo "$(GREEN)Terraform files formatted$(NC)"

lint: ## Lint Terraform files
	@echo "$(BLUE)Linting Terraform files...$(NC)"
	@terraform fmt -check -recursive . || { echo "$(YELLOW)Some files need formatting. Run 'make format'$(NC)"; }
	@cd environments/$(ENV) && terraform validate
	@echo "$(GREEN)Terraform files are valid$(NC)"

init: check-deps ## Initialize Terraform for specified environment
	@echo "$(BLUE)Initializing Terraform for $(ENV) environment...$(NC)"
	@cd environments/$(ENV) && terraform init
	@echo "$(GREEN)Terraform initialized$(NC)"

plan: validate init ## Create Terraform plan for specified environment
	@echo "$(BLUE)Creating Terraform plan for $(ENV) environment...$(NC)"
	@./scripts/deploy.sh $(ENV) plan

apply: validate init ## Apply Terraform changes for specified environment
	@echo "$(BLUE)Applying Terraform changes for $(ENV) environment...$(NC)"
	@./scripts/deploy.sh $(ENV) apply

destroy: init ## Destroy all resources in specified environment
	@echo "$(RED)WARNING: This will destroy all resources in $(ENV) environment!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@./scripts/deploy.sh $(ENV) destroy

clean: ## Clean up Terraform files
	@echo "$(BLUE)Cleaning up Terraform files...$(NC)"
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfstate*" -type f -delete 2>/dev/null || true
	@find . -name "*.terraform.lock.hcl" -type f -delete 2>/dev/null || true
	@find . -name "tfplan-*" -type f -delete 2>/dev/null || true
	@echo "$(GREEN)Cleanup completed$(NC)"

show: init ## Show current Terraform state for specified environment
	@echo "$(BLUE)Showing Terraform state for $(ENV) environment...$(NC)"
	@cd environments/$(ENV) && terraform show

output: init ## Show Terraform outputs for specified environment
	@echo "$(BLUE)Showing Terraform outputs for $(ENV) environment...$(NC)"
	@cd environments/$(ENV) && terraform output

refresh: init ## Refresh Terraform state for specified environment
	@echo "$(BLUE)Refreshing Terraform state for $(ENV) environment...$(NC)"
	@cd environments/$(ENV) && terraform refresh

docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@terraform-docs markdown table --output-file README.md modules/ipam/
	@terraform-docs markdown table --output-file README.md modules/dns/
	@echo "$(GREEN)Documentation generated$(NC)"

test: validate lint ## Run all tests and validations
	@echo "$(BLUE)Running all tests and validations...$(NC)"
	@for env in dev staging prod; do \
		echo "Testing $$env environment..."; \
		make validate ENV=$$env; \
	done
	@echo "$(GREEN)All tests passed$(NC)"

setup-dev: ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
	@echo "$(YELLOW)Please edit environments/dev/terraform.tfvars with your configuration$(NC)"
	@echo "$(GREEN)Development environment setup completed$(NC)"

setup-staging: ## Set up staging environment
	@echo "$(BLUE)Setting up staging environment...$(NC)"
	@cp environments/staging/terraform.tfvars.example environments/staging/terraform.tfvars 2>/dev/null || true
	@echo "$(YELLOW)Please edit environments/staging/terraform.tfvars with your configuration$(NC)"
	@echo "$(GREEN)Staging environment setup completed$(NC)"

backup-state: ## Backup Terraform state for specified environment
	@echo "$(BLUE)Backing up Terraform state for $(ENV) environment...$(NC)"
	@mkdir -p backups
	@cd environments/$(ENV) && cp terraform.tfstate ../../backups/terraform.tfstate.$(ENV).$$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "No state file to backup"
	@echo "$(GREEN)State backup completed$(NC)"

# Development helpers
dev-plan: ## Quick plan for dev environment
	@make plan ENV=dev

dev-apply: ## Quick apply for dev environment
	@make apply ENV=dev

dev-destroy: ## Quick destroy for dev environment
	@make destroy ENV=dev

staging-plan: ## Quick plan for staging environment
	@make plan ENV=staging

staging-apply: ## Quick apply for staging environment
	@make apply ENV=staging

prod-plan: ## Quick plan for production environment
	@make plan ENV=prod

prod-apply: ## Quick apply for production environment (with extra confirmation)
	@echo "$(RED)WARNING: You are about to apply changes to PRODUCTION!$(NC)"
	@read -p "Type 'PRODUCTION' to confirm: " confirm && [ "$$confirm" = "PRODUCTION" ] || exit 1
	@make apply ENV=prod

# Terragrunt targets
tg-plan: check-terragrunt ## Plan with Terragrunt for specified environment
	@echo "$(BLUE)Planning with Terragrunt for $(ENV) environment...$(NC)"
	@./scripts/terragrunt-deploy.sh $(ENV) plan

tg-apply: check-terragrunt ## Apply with Terragrunt for specified environment
	@echo "$(BLUE)Applying with Terragrunt for $(ENV) environment...$(NC)"
	@./scripts/terragrunt-deploy.sh $(ENV) apply

tg-destroy: check-terragrunt ## Destroy with Terragrunt for specified environment
	@echo "$(RED)WARNING: This will destroy all resources in $(ENV) environment!$(NC)"
	@./scripts/terragrunt-deploy.sh $(ENV) destroy

tg-output: check-terragrunt ## Show Terragrunt outputs for specified environment
	@echo "$(BLUE)Showing Terragrunt outputs for $(ENV) environment...$(NC)"
	@./scripts/terragrunt-deploy.sh $(ENV) output

tg-plan-all: check-terragrunt ## Plan all environments with Terragrunt
	@echo "$(BLUE)Planning all environments with Terragrunt...$(NC)"
	@./scripts/terragrunt-deploy.sh all plan

tg-graph: check-terragrunt ## Generate dependency graph with Terragrunt
	@echo "$(BLUE)Generating dependency graph with Terragrunt...$(NC)"
	@./scripts/terragrunt-deploy.sh all graph

tg-clean: ## Clean Terragrunt cache
	@echo "$(BLUE)Cleaning Terragrunt cache...$(NC)"
	@find live -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)Terragrunt cache cleaned$(NC)"

# Quick Terragrunt commands
tg-dev-plan: ## Quick Terragrunt plan for dev environment
	@make tg-plan ENV=dev

tg-dev-apply: ## Quick Terragrunt apply for dev environment
	@make tg-apply ENV=dev

tg-staging-plan: ## Quick Terragrunt plan for staging environment
	@make tg-plan ENV=staging

tg-staging-apply: ## Quick Terragrunt apply for staging environment
	@make tg-apply ENV=staging

tg-prod-plan: ## Quick Terragrunt plan for production environment
	@make tg-plan ENV=prod

tg-prod-apply: ## Quick Terragrunt apply for production environment (with extra confirmation)
	@echo "$(RED)WARNING: You are about to apply changes to PRODUCTION!$(NC)"
	@make tg-apply ENV=prod

# Default target
.DEFAULT_GOAL := help
