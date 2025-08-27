# Scripts

Utility scripts for managing the Factorio AWS deployment.

## Scripts

### `deploy.sh`
Deploys the complete infrastructure:
- Initializes Terraform
- Plans the deployment  
- Applies the configuration
- Shows deployment outputs

### `destroy.sh` 
Safely destroys all AWS resources:
- Prompts for confirmation
- Destroys infrastructure via Terraform

### `test_api.sh`
Tests the deployed API endpoints:
- Gets current server status
- Tests start command
- Tests stop command
- Shows HTTP response codes

## Usage

All scripts should be run from the project root directory:

```bash
# Deploy infrastructure
./scripts/deploy.sh

# Test the API
./scripts/test_api.sh

# Destroy infrastructure
./scripts/destroy.sh
```