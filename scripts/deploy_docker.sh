#!/bin/bash
set -e

echo "🚀 Deploying Factorio AWS Docker Server..."

# Check if terraform.tfvars exists
if [ ! -f "infrastructure/terraform.tfvars" ]; then
    echo "❌ infrastructure/terraform.tfvars not found. Please copy infrastructure/terraform.tfvars.example to infrastructure/terraform.tfvars and fill in your values."
    exit 1
fi

# Change to infrastructure directory
cd infrastructure

# Copy Docker-optimized files for deployment
echo "📦 Preparing Docker-optimized configuration..."
cp main_docker.tf main.tf
cp variables_docker.tf variables.tf
cp ../lambda/src/lambda_function_docker.py ../lambda/src/lambda_function.py

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning Docker deployment..."
terraform plan

# Ask for confirmation
read -p "Do you want to proceed with the Docker deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

# Apply the configuration
echo "🏗️  Applying Terraform configuration..."
terraform apply -auto-approve

# Get outputs
echo "✅ Docker deployment complete!"
echo
echo "📊 Deployment Information:"
terraform output

echo
echo "🎮 Your Factorio Docker server will be available at:"
echo "   $(terraform output -raw factorio_server_address)"
echo
echo "🌐 API endpoints (with Docker container management):"
echo "   Start:   POST $(terraform output -raw api_gateway_url | sed 's|/prod/server|/prod/server/start|')"
echo "   Stop:    POST $(terraform output -raw api_gateway_url | sed 's|/prod/server|/prod/server/stop|')"
echo "   Status:  POST $(terraform output -raw api_gateway_url | sed 's|/prod/server|/prod/server/status|')"
echo "   Restart: POST $(terraform output -raw api_gateway_url | sed 's|/prod/server|/prod/server/restart|')"
echo
echo "💰 Cost Optimization Benefits:"
echo "   - Instance type: t3.small (vs t3.medium) - ~50% cost savings"
echo "   - Faster startup: 30-60 seconds (vs 2-3 minutes)"
echo "   - Better resource utilization with Docker containers"
echo
echo "⏱️  Note: The EC2 instance will take a few minutes to initialize Docker and build the Factorio image."
echo "💡 Run './scripts/test_api.sh' to test the API endpoints after deployment."