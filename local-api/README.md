# Local API Gateway

This directory contains a local Flask-based API server that simulates AWS API Gateway + Lambda functionality for local development and testing.

## Features

- **Complete API Simulation**: Mimics AWS API Gateway endpoints
- **Docker Integration**: Manages Factorio Docker containers
- **Real-time Monitoring**: Container status and health checks
- **CORS Support**: Web-based client testing
- **Comprehensive Logging**: Request/response logging and Factorio server logs

## API Endpoints

### Server Management
- `POST /server/start` - Start the Factorio server
- `POST /server/stop` - Stop the Factorio server
- `POST /server/status` - Get current server status
- `POST /server/restart` - Restart the Factorio server

### Information & Monitoring
- `GET /health` - API health check
- `GET /info` - API and server information
- `GET /server/logs` - Get Factorio server logs

## Response Format

All server management endpoints return JSON in this format:

```json
{
  "action_requested": "start|stop|status|restart",
  "container_name": "factorio-server-local",
  "container_status": "running|stopped|starting|stopping",
  "container_health": "healthy|unhealthy|starting",
  "message": "Human readable status message",
  "local_api": true,
  "timestamp": 1234567890.123
}
```

## Development Setup

### Standalone Mode
```bash
# Install dependencies
pip install -r requirements.txt

# Run the API server
python app.py
```

### Docker Mode
```bash
# Build the image
docker build -t factorio-local-api .

# Run with Docker
docker run -p 5000:5000 -v /var/run/docker.sock:/var/run/docker.sock factorio-local-api
```

### Full Stack Mode
```bash
# Start both API and Factorio
docker-compose -f ../docker-compose.full.yml up -d
```

## Testing

```bash
# Health check
curl http://localhost:5000/health

# Get server info
curl http://localhost:5000/info

# Start Factorio server
curl -X POST http://localhost:5000/server/start

# Check status
curl -X POST http://localhost:5000/server/status

# View logs
curl http://localhost:5000/server/logs

# Stop server
curl -X POST http://localhost:5000/server/stop
```

## Implementation Details

### Docker Integration
- Uses Docker Python SDK for container management
- Monitors container health and status
- Executes docker-compose commands for lifecycle management

### Security Considerations
- **Local Use Only**: Not intended for production deployment
- **Docker Socket Access**: Requires Docker socket mount for container management
- **No Authentication**: Open access for local development

### Error Handling
- Graceful handling of Docker daemon connectivity issues
- Timeout protection for long-running operations
- Detailed error messages for debugging

## Architecture Comparison

| Component | AWS Production | Local Development |
|-----------|----------------|------------------|
| API Gateway | AWS API Gateway | Flask HTTP Server |
| Lambda | Python Lambda Function | Flask Route Handler |
| EC2 Control | boto3 ec2 client | Docker Python SDK |
| Container Management | SSM Commands | docker-compose |
| Networking | VPC + Security Groups | Docker Networks |
| Monitoring | CloudWatch | Container Health Checks |

## Benefits

1. **Fast Development**: No AWS deployment needed for testing
2. **Cost-Free**: No AWS charges during development
3. **Full Feature Parity**: Same API endpoints as production
4. **Easy Debugging**: Local logs and direct access
5. **Rapid Iteration**: Instant code changes without deployment

## Limitations

- Docker socket access required
- Mac/Linux only (Windows requires WSL)
- No AWS-specific features (IAM, CloudWatch, etc.)
- Single-container deployment only