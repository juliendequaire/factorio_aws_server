#!/bin/bash
set -e

echo "🗑️  Destroying Factorio AWS Server infrastructure..."

# Ask for confirmation
echo "⚠️  WARNING: This will destroy all AWS resources created by this project!"
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Destruction cancelled."
    exit 1
fi

# Change to infrastructure directory
cd infrastructure

# Destroy the infrastructure
echo "💥 Destroying Terraform infrastructure..."
terraform destroy -auto-approve

echo "✅ Infrastructure destroyed successfully!"