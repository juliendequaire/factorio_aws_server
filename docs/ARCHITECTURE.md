# Architecture Documentation

## Overview

The Factorio AWS Server uses a serverless architecture to control an EC2 instance running Factorio through HTTP API calls.

## Components

### 1. EC2 Instance
- **Purpose**: Hosts the Factorio headless server
- **Instance Type**: t3.medium (configurable)
- **OS**: Ubuntu 22.04 LTS
- **Network**: Public subnet with Internet Gateway
- **Storage**: Default EBS volume (8GB)

### 2. Lambda Function
- **Purpose**: Controls EC2 instance start/stop operations
- **Runtime**: Python 3.11
- **Permissions**: EC2 start/stop/describe instances
- **Environment**: Instance ID injected via Terraform

### 3. API Gateway
- **Purpose**: Provides HTTP endpoints for server control
- **Type**: REST API
- **Endpoints**: `/server/{action}` where action is start|stop|status
- **Method**: POST
- **Integration**: AWS_PROXY to Lambda

### 4. VPC Infrastructure
- **VPC**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24 (public)
- **Internet Gateway**: For public internet access
- **Route Table**: Routes 0.0.0.0/0 to IGW

### 5. Security Groups
- **Factorio SG**: 
  - SSH (22/tcp) from 0.0.0.0/0
  - Factorio (34197/udp) from 0.0.0.0/0
  - All outbound traffic allowed

### 6. IAM Roles
- **EC2 Role**: Basic role for instance (extensible for CloudWatch, etc.)
- **Lambda Role**: 
  - CloudWatch Logs permissions
  - EC2 start/stop/describe permissions

## Data Flow

```
Client Request → API Gateway → Lambda Function → EC2 API → EC2 Instance
                     ↓
                 HTTP Response ← Lambda Response ← EC2 Status
```

## Network Architecture

```
Internet
    ↓
Internet Gateway
    ↓
Public Subnet (10.0.1.0/24)
    ↓
EC2 Instance (Factorio Server)
```

## Security Considerations

1. **Network Security**:
   - EC2 in public subnet (required for game connectivity)
   - Security group restricts access to necessary ports only

2. **IAM Security**:
   - Lambda has minimal required permissions
   - No hardcoded credentials
   - Instance profile for EC2 extensibility

3. **API Security**:
   - No authentication implemented (add API key for production)
   - CORS enabled for web client access

## Scalability

### Current Limitations:
- Single EC2 instance
- No auto-scaling
- No load balancing

### Potential Improvements:
- Multi-AZ deployment
- Auto Scaling Groups
- Application Load Balancer
- CloudWatch monitoring
- SNS notifications

## Cost Optimization

1. **Stop when unused**: Primary cost savings mechanism
2. **Instance sizing**: t3.medium suitable for small-medium servers
3. **Spot instances**: Could reduce costs by ~70% (with interruption risk)
4. **Reserved instances**: For predictable usage patterns

## Monitoring

### Available Metrics:
- EC2 CloudWatch metrics (CPU, network, disk)
- Lambda execution metrics
- API Gateway request metrics

### Logging:
- Lambda logs in CloudWatch
- EC2 system logs via SSH
- Factorio server logs: `/opt/factorio/factorio-current.log`