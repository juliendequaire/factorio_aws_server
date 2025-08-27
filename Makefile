.PHONY: help deploy destroy test status init plan

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	@echo "🔧 Initializing Terraform..."
	@cd infrastructure && terraform init

plan: ## Plan Terraform deployment
	@echo "📋 Planning deployment..."
	@cd infrastructure && terraform plan

deploy: ## Deploy the Factorio server infrastructure
	@./scripts/deploy.sh

destroy: ## Destroy all AWS resources
	@./scripts/destroy.sh

test: ## Test the API endpoints
	@./scripts/test_api.sh

status: ## Get current deployment status
	@echo "📊 Current deployment status:"
	@cd infrastructure && terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_instance") | .values | "Instance: \(.tags.Name) (\(.instance_id)) - State: \(.instance_state)"' 2>/dev/null || echo "No deployment found or jq not installed"

validate: ## Validate Terraform configuration
	@echo "✅ Validating Terraform configuration..."
	@cd infrastructure && terraform validate

fmt: ## Format Terraform files
	@echo "🎨 Formatting Terraform files..."
	@cd infrastructure && terraform fmt

clean: ## Clean up temporary files
	@echo "🧹 Cleaning up temporary files..."
	@rm -rf infrastructure/.terraform/
	@rm -f infrastructure/terraform.tfstate*
	@rm -f infrastructure/lambda_function.zip