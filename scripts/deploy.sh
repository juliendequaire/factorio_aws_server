#!/bin/bash
set -e

echo "🚀 Deploying Factorio AWS Server..."

# Check if terraform.tfvars exists
if [ ! -f "infrastructure/terraform.tfvars" ]; then
    echo "❌ infrastructure/terraform.tfvars not found. Please copy infrastructure/terraform.tfvars.example to infrastructure/terraform.tfvars and fill in your values."
    exit 1
fi

# Change to infrastructure directory
cd infrastructure

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning deployment..."
terraform plan

# Ask for confirmation
read -p "Do you want to proceed with the deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

# Apply the configuration
echo "🏗️  Applying Terraform configuration..."
terraform apply -auto-approve

# Get outputs
echo "✅ Deployment complete!"
echo
echo "📊 Deployment Information:"
terraform output

echo
echo "🎮 Your Factorio server will be available at:"
echo "   $(terraform output -raw factorio_server_address)"
echo
echo "🌐 API endpoints:"
echo "   Start:  POST $(terraform output -raw api_gateway_url | sed 's|/prod/server|/prod/server/start|')"
echo "   Stop:   POST $(terraform output -raw api_gateway_url | sed 's|/prod/server|/prod/server/stop|')"
echo "   Status: POST $(terraform output -raw api_gateway_url | sed 's|/prod/server|/prod/server/status|')"
echo
echo "⏱️  Note: The EC2 instance will take a few minutes to fully initialize and install Factorio."
echo
echo "💡 Run './scripts/test_api.sh' to test the API endpoints after deployment."