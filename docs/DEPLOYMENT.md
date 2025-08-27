# Deployment Guide

## Prerequisites

### Required Tools
- **AWS CLI**: Configured with appropriate permissions
- **Terraform**: Version >= 1.0
- **SSH Key Pair**: For EC2 access

### AWS Permissions
Your AWS user/role needs the following permissions:
- EC2: Full access (for instances, VPC, security groups)
- Lambda: Full access  
- API Gateway: Full access
- IAM: CreateRole, AttachRolePolicy, CreateInstanceProfile
- CloudWatch: Basic logging permissions

## Step-by-Step Deployment

### 1. Clone Repository
```bash
git clone <repository-url>
cd factorio_aws_server
```

### 2. Configure Variables
```bash
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
```

Edit `infrastructure/terraform.tfvars`:
```hcl
aws_region    = "us-east-1"                    # Your preferred region
instance_type = "t3.medium"                    # Instance size
public_key    = "ssh-rsa AAAAB3NzaC1yc2E..."  # Your SSH public key
```

### 3. Deploy Infrastructure
```bash
./scripts/deploy.sh
```

This script will:
- Initialize Terraform
- Show deployment plan
- Ask for confirmation
- Apply the configuration
- Display outputs including API endpoints

### 4. Wait for Initialization
The EC2 instance takes 2-3 minutes to:
- Install Factorio server
- Configure systemd service  
- Create initial game save

### 5. Test the Deployment
```bash
./scripts/test_api.sh
```

## Configuration Options

### Instance Types
- **t3.small**: 2 vCPU, 2GB RAM - Small servers (5-10 players)
- **t3.medium**: 2 vCPU, 4GB RAM - Medium servers (10-20 players) 
- **t3.large**: 2 vCPU, 8GB RAM - Large servers (20+ players)
- **c5.large**: 2 vCPU, 4GB RAM - CPU optimized for large factories

### Regions
Choose region close to your players:
- **us-east-1**: US East (Virginia) - Default, lowest cost
- **us-west-2**: US West (Oregon)  
- **eu-west-1**: Europe (Ireland)
- **ap-southeast-1**: Asia Pacific (Singapore)

## Post-Deployment Configuration

### 1. Server Settings
SSH to your instance:
```bash
ssh -i ~/.ssh/your-key ubuntu@<instance-ip>
```

Edit server configuration:
```bash
sudo vim /opt/factorio/data/server-settings.json
```

Common settings to modify:
```json
{
  "name": "Your Server Name",
  "description": "Server description", 
  "game_password": "optional-password",
  "max_players": 20,
  "visibility": {
    "public": true,  # Make visible in server browser
    "lan": false
  }
}
```

### 2. Restart Server
After configuration changes:
```bash
sudo systemctl restart factorio
```

### 3. Upload Existing Save (Optional)
```bash
# Copy save file to server
scp -i ~/.ssh/your-key your-save.zip ubuntu@<instance-ip>:/tmp/

# On server, move to factorio saves directory
ssh -i ~/.ssh/your-key ubuntu@<instance-ip>
sudo mv /tmp/your-save.zip /opt/factorio/saves/
sudo chown factorio:factorio /opt/factorio/saves/your-save.zip

# Update service to load your save
sudo vim /etc/systemd/system/factorio.service
# Change: --start-server-load-latest
# To:     --start-server /opt/factorio/saves/your-save.zip

sudo systemctl daemon-reload
sudo systemctl restart factorio
```

## Troubleshooting

### Deployment Issues

**Terraform errors**:
```bash
cd infrastructure
terraform validate  # Check syntax
terraform plan      # Review changes
```

**Permission errors**:
- Check AWS CLI configuration: `aws sts get-caller-identity`
- Verify IAM permissions
- Ensure region is correct

### Server Issues

**Server won't start**:
```bash
# Check service status
sudo systemctl status factorio

# Check logs  
sudo journalctl -u factorio -f

# Check Factorio logs
sudo tail -f /opt/factorio/factorio-current.log
```

**Can't connect to server**:
- Wait 2-3 minutes for full initialization
- Check server status via API
- Verify security group allows UDP 34197
- Check if server is actually running: `sudo systemctl status factorio`

**API not responding**:
- Check Lambda logs in AWS CloudWatch
- Verify API Gateway deployment
- Test with curl using exact URLs from output

## Updating

### Terraform Changes
```bash
cd infrastructure
terraform plan
terraform apply
```

### Lambda Function Updates
After modifying `lambda/src/lambda_function.py`:
```bash
cd infrastructure  
terraform apply  # Will recreate Lambda with new code
```

### Factorio Server Updates
SSH to instance and update manually:
```bash
sudo systemctl stop factorio
# Download new version, extract, update symlinks
sudo systemctl start factorio
```