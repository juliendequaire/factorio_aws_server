# Factorio AWS Server

A Terraform-based solution to deploy a Factorio server on AWS EC2 with HTTP API control for start, stop, and status operations.

## Features

- 🚀 Automated EC2 deployment with Factorio server
- 🌐 REST API via AWS API Gateway and Lambda
- ⚡ Start, stop, and status commands via HTTP requests
- 🔒 Secure infrastructure with proper IAM roles
- 📦 One-command deployment and destruction

## Architecture

```
Internet → API Gateway → Lambda → EC2 (Factorio Server)
```

- **EC2 Instance**: Runs the Factorio headless server
- **Lambda Function**: Handles start/stop/status commands
- **API Gateway**: Provides HTTP endpoints
- **VPC**: Isolated network environment

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- SSH key pair for EC2 access

## Quick Start

1. **Clone and setup**:
   ```bash
   git clone <this-repo>
   cd factorio_aws_server
   ```

2. **Configure variables**:
   ```bash
   cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
   # Edit infrastructure/terraform.tfvars with your values
   ```

3. **Deploy**:
   ```bash
   ./deploy.sh
   ```

4. **Test the API**:
   ```bash
   ./test_api.sh
   ```

## API Endpoints

After deployment, you'll get three endpoints:

- `POST /prod/server/start` - Start the Factorio server
- `POST /prod/server/stop` - Stop the Factorio server  
- `POST /prod/server/status` - Get server status

### Example Usage

```bash
# Get server status
curl -X POST https://your-api-id.execute-api.region.amazonaws.com/prod/server/status

# Start server
curl -X POST https://your-api-id.execute-api.region.amazonaws.com/prod/server/start

# Stop server
curl -X POST https://your-api-id.execute-api.region.amazonaws.com/prod/server/stop
```

## Configuration

### infrastructure/terraform.tfvars

```hcl
aws_region    = "us-east-1"        # AWS region
instance_type = "t3.medium"        # EC2 instance type
public_key    = "ssh-rsa AAAA..."  # Your SSH public key
```

### Server Settings

Modify `/opt/factorio/data/server-settings.json` on the EC2 instance to customize:
- Server name and description
- Password protection
- Player limits
- Admin settings

## Costs

Estimated AWS costs (us-east-1):
- EC2 t3.medium: ~$30/month (when running)
- Lambda: ~$0 (free tier covers typical usage)
- API Gateway: ~$0 (free tier covers typical usage)
- Data transfer: varies

💡 **Tip**: Stop the server when not in use to minimize costs!

## File Structure

```
├── infrastructure/          # Terraform infrastructure code
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Variable definitions  
│   ├── outputs.tf          # Output definitions
│   ├── user_data.sh        # EC2 initialization script
│   └── terraform.tfvars.example
├── lambda/                 # Lambda function code
│   ├── src/
│   │   └── lambda_function.py
│   ├── requirements.txt
│   └── README.md
├── scripts/               # Deployment and utility scripts
│   ├── deploy.sh          # Deployment script
│   ├── destroy.sh         # Destruction script
│   ├── test_api.sh        # API testing script
│   └── README.md
└── docs/                  # Documentation
    ├── ARCHITECTURE.md    # Architecture overview
    ├── DEPLOYMENT.md      # Deployment guide
    └── API.md            # API documentation
```

## Cleanup

To destroy all resources:

```bash
./destroy.sh
```

## Troubleshooting

### Server not starting
- Check EC2 instance logs: `sudo journalctl -u factorio -f`
- Ensure security group allows UDP port 34197

### API not responding
- Check Lambda logs in CloudWatch
- Verify IAM permissions

### Can't connect to Factorio
- Server takes 2-3 minutes to fully initialize
- Check server status via API first

## Security Notes

- EC2 instance is in a public subnet for game access
- SSH access is restricted to your IP (modify security group as needed)
- Lambda has minimal required EC2 permissions
- No passwords are stored in code (configure in server settings)