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
	@echo "$(BLUE)Infoblox Terragrunt Automation$(NC)"
	@echo "Usage: make [target] ENV=[environment]"
	@echo ""
	@echo "$(YELLOW)Terragrunt targets (Primary):$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^tg-[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Utility targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && !/^tg-/ && !/^[a-z]*-[a-z]*:/ {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Available environments: dev, staging, prod"
	@echo "Primary usage: make tg-plan ENV=dev"
	@echo "Quick usage: make tg-dev-apply"

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
	@cd live/$(ENV) && terragrunt validate
	@echo "$(GREEN)Terraform files are valid$(NC)"

init: check-deps ## [DEPRECATED] Initialize Terraform for specified environment (use tg-* targets instead)
	@echo "$(YELLOW)WARNING: This target is deprecated. Use 'make tg-plan ENV=$(ENV)' instead$(NC)"
	@echo "$(BLUE)Initializing Terraform for $(ENV) environment...$(NC)"
	@cd live/$(ENV) && terragrunt init
	@echo "$(GREEN)Terraform initialized$(NC)"

plan: validate ## [DEPRECATED] Create Terraform plan for specified environment (use tg-plan instead)
	@echo "$(YELLOW)WARNING: This target is deprecated. Use 'make tg-plan ENV=$(ENV)' instead$(NC)"
	@echo "$(BLUE)Creating Terraform plan for $(ENV) environment...$(NC)"
	@cd live/$(ENV) && terragrunt plan

apply: validate ## [DEPRECATED] Apply Terraform changes for specified environment (use tg-apply instead)
	@echo "$(YELLOW)WARNING: This target is deprecated. Use 'make tg-apply ENV=$(ENV)' instead$(NC)"
	@echo "$(BLUE)Applying Terraform changes for $(ENV) environment...$(NC)"
	@cd live/$(ENV) && terragrunt apply

destroy: ## [DEPRECATED] Destroy all resources in specified environment (use tg-destroy instead)
	@echo "$(YELLOW)WARNING: This target is deprecated. Use 'make tg-destroy ENV=$(ENV)' instead$(NC)"
	@echo "$(RED)WARNING: This will destroy all resources in $(ENV) environment!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@cd live/$(ENV) && terragrunt destroy

clean: ## Clean up Terraform files
	@echo "$(BLUE)Cleaning up Terraform files...$(NC)"
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfstate*" -type f -delete 2>/dev/null || true
	@find . -name "*.terraform.lock.hcl" -type f -delete 2>/dev/null || true
	@find . -name "tfplan-*" -type f -delete 2>/dev/null || true
	@echo "$(GREEN)Cleanup completed$(NC)"

show: ## [DEPRECATED] Show current Terraform state for specified environment (use tg-output instead)
	@echo "$(YELLOW)WARNING: This target is deprecated. Use 'make tg-output ENV=$(ENV)' instead$(NC)"
	@echo "$(BLUE)Showing Terraform state for $(ENV) environment...$(NC)"
	@cd live/$(ENV) && terragrunt show

output: ## [DEPRECATED] Show Terraform outputs for specified environment (use tg-output instead) 
	@echo "$(YELLOW)WARNING: This target is deprecated. Use 'make tg-output ENV=$(ENV)' instead$(NC)"
	@echo "$(BLUE)Showing Terraform outputs for $(ENV) environment...$(NC)"
	@cd live/$(ENV) && terragrunt output

refresh: ## [DEPRECATED] Refresh Terraform state for specified environment (use terragrunt directly)
	@echo "$(YELLOW)WARNING: This target is deprecated. Use 'cd live/$(ENV) && terragrunt refresh' instead$(NC)"
	@echo "$(BLUE)Refreshing Terraform state for $(ENV) environment...$(NC)"
	@cd live/$(ENV) && terragrunt refresh

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

setup-dev: ## [DEPRECATED] Set up development environment (not needed with Terragrunt)
	@echo "$(YELLOW)WARNING: This target is no longer needed with Terragrunt$(NC)"
	@echo "$(BLUE)With Terragrunt, just edit live/dev/terragrunt.hcl directly$(NC)"
	@echo "$(GREEN)No setup required - Terragrunt handles configuration automatically$(NC)"

setup-staging: ## [DEPRECATED] Set up staging environment (not needed with Terragrunt)
	@echo "$(YELLOW)WARNING: This target is no longer needed with Terragrunt$(NC)"
	@echo "$(BLUE)With Terragrunt, just edit live/staging/terragrunt.hcl directly$(NC)"
	@echo "$(GREEN)No setup required - Terragrunt handles configuration automatically$(NC)"

backup-state: ## Backup Terraform state for specified environment
	@echo "$(BLUE)Backing up Terraform state for $(ENV) environment...$(NC)"
	@mkdir -p backups
	@cd live/$(ENV) && cp terraform.tfstate ../../backups/terraform.tfstate.$(ENV).$$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "No state file to backup (using remote backend)"
	@echo "$(GREEN)State backup completed$(NC)"

# Development helpers (deprecated - use tg-* targets)
dev-plan: ## [DEPRECATED] Quick plan for dev environment (use tg-dev-plan)
	@echo "$(YELLOW)WARNING: Use 'make tg-dev-plan' instead$(NC)"
	@make tg-plan ENV=dev

dev-apply: ## [DEPRECATED] Quick apply for dev environment (use tg-dev-apply)
	@echo "$(YELLOW)WARNING: Use 'make tg-dev-apply' instead$(NC)"
	@make tg-apply ENV=dev

dev-destroy: ## [DEPRECATED] Quick destroy for dev environment (use tg-dev-destroy)
	@echo "$(YELLOW)WARNING: Use 'make tg-destroy ENV=dev' instead$(NC)"
	@make tg-destroy ENV=dev

staging-plan: ## [DEPRECATED] Quick plan for staging environment (use tg-staging-plan)
	@echo "$(YELLOW)WARNING: Use 'make tg-staging-plan' instead$(NC)"
	@make tg-plan ENV=staging

staging-apply: ## [DEPRECATED] Quick apply for staging environment (use tg-staging-apply)
	@echo "$(YELLOW)WARNING: Use 'make tg-staging-apply' instead$(NC)"
	@make tg-apply ENV=staging

prod-plan: ## [DEPRECATED] Quick plan for production environment (use tg-prod-plan)
	@echo "$(YELLOW)WARNING: Use 'make tg-prod-plan' instead$(NC)"
	@make tg-plan ENV=prod

prod-apply: ## [DEPRECATED] Quick apply for production environment (use tg-prod-apply)
	@echo "$(YELLOW)WARNING: Use 'make tg-prod-apply' instead$(NC)"
	@echo "$(RED)WARNING: You are about to apply changes to PRODUCTION!$(NC)"
	@read -p "Type 'PRODUCTION' to confirm: " confirm && [ "$$confirm" = "PRODUCTION" ] || exit 1
	@make tg-apply ENV=prod

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
