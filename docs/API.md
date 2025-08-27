# API Documentation

## Overview

The Factorio server control API provides three endpoints to manage the EC2 instance running the Factorio server.

## Base URL

After deployment, your API base URL will be:
```
https://{api-id}.execute-api.{region}.amazonaws.com/prod
```

Get the exact URL from Terraform output:
```bash
cd infrastructure
terraform output api_gateway_url
```

## Authentication

Currently no authentication is required. For production use, consider adding API keys or other authentication mechanisms.

## Endpoints

### Server Status

Get the current status of the Factorio server.

**Endpoint**: `POST /server/status`

**Request**:
```bash
curl -X POST https://your-api-url.com/prod/server/status \
  -H "Content-Type: application/json"
```

**Response**:
```json
{
  "instance_id": "i-1234567890abcdef0",
  "current_state": "running",
  "public_ip": "54.123.45.67",
  "action_requested": "status",
  "message": "Server is currently running"
}
```

### Start Server

Start the Factorio server if it's currently stopped.

**Endpoint**: `POST /server/start`

**Request**:
```bash
curl -X POST https://your-api-url.com/prod/server/start \
  -H "Content-Type: application/json"
```

**Response** (when stopped):
```json
{
  "instance_id": "i-1234567890abcdef0", 
  "current_state": "stopped",
  "public_ip": "N/A",
  "action_requested": "start",
  "message": "Start command sent. Server will be available shortly."
}
```

**Response** (already running):
```json
{
  "instance_id": "i-1234567890abcdef0",
  "current_state": "running", 
  "public_ip": "54.123.45.67",
  "action_requested": "start",
  "message": "Server is already running"
}
```

### Stop Server

Stop the Factorio server if it's currently running.

**Endpoint**: `POST /server/stop`

**Request**:
```bash
curl -X POST https://your-api-url.com/prod/server/stop \
  -H "Content-Type: application/json"
```

**Response** (when running):
```json
{
  "instance_id": "i-1234567890abcdef0",
  "current_state": "running",
  "public_ip": "54.123.45.67", 
  "action_requested": "stop",
  "message": "Stop command sent. Server is shutting down."
}
```

**Response** (already stopped):
```json
{
  "instance_id": "i-1234567890abcdef0",
  "current_state": "stopped",
  "public_ip": "N/A",
  "action_requested": "stop", 
  "message": "Server is already stopped"
}
```

## Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `instance_id` | string | AWS EC2 instance identifier |
| `current_state` | string | Current EC2 state: `pending`, `running`, `stopping`, `stopped`, `terminated` |
| `public_ip` | string | Public IP address when running, "N/A" when stopped |
| `action_requested` | string | The action that was requested: `start`, `stop`, `status` |
| `message` | string | Human-readable status message |

## Error Responses

### Invalid Action
**Status**: 400 Bad Request
```json
{
  "error": "Invalid action. Use start, stop, or status"
}
```

### Internal Server Error  
**Status**: 500 Internal Server Error
```json
{
  "error": "Detailed error message",
  "message": "Internal server error"
}
```

## EC2 Instance States

Understanding EC2 states helps interpret API responses:

| State | Description | Can Start? | Can Stop? |
|-------|-------------|------------|-----------|
| `pending` | Starting up | No | Yes |
| `running` | Fully operational | No | Yes |  
| `stopping` | Shutting down | No | No |
| `stopped` | Fully stopped | Yes | No |
| `terminated` | Permanently destroyed | No | No |

## Rate Limiting

No explicit rate limiting is configured, but AWS Lambda has built-in concurrency limits. For high-frequency requests, consider:
- Implementing client-side throttling
- Adding API Gateway rate limiting
- Using exponential backoff for retries

## CORS

Cross-Origin Resource Sharing (CORS) is enabled with:
- `Access-Control-Allow-Origin: *`

For production, consider restricting to specific origins.

## Usage Examples

### JavaScript/Browser
```javascript
async function getServerStatus() {
  const response = await fetch('https://your-api-url.com/prod/server/status', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    }
  });
  
  const data = await response.json();
  console.log('Server status:', data.current_state);
  return data;
}

async function startServer() {
  const response = await fetch('https://your-api-url.com/prod/server/start', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    }
  });
  
  const data = await response.json();
  console.log(data.message);
  return data;
}
```

### Python
```python
import requests

API_BASE = "https://your-api-url.com/prod"

def get_server_status():
    response = requests.post(f"{API_BASE}/server/status")
    return response.json()

def start_server():
    response = requests.post(f"{API_BASE}/server/start") 
    return response.json()

def stop_server():
    response = requests.post(f"{API_BASE}/server/stop")
    return response.json()
```

## Monitoring

Monitor API usage through:
- **CloudWatch Logs**: Lambda function logs
- **API Gateway Metrics**: Request count, latency, errors
- **Lambda Metrics**: Duration, errors, throttles