# Lambda Function

This directory contains the AWS Lambda function that controls the Factorio EC2 instance.

## Structure

- `src/lambda_function.py` - Main Lambda handler
- `requirements.txt` - Python dependencies

## Function Details

The Lambda function accepts HTTP requests through API Gateway and performs the following operations:

- **Start**: Starts the EC2 instance if it's stopped
- **Stop**: Stops the EC2 instance if it's running  
- **Status**: Returns the current state of the EC2 instance

## Environment Variables

- `INSTANCE_ID` - The EC2 instance ID to control (set by Terraform)

## API Response Format

```json
{
  "instance_id": "i-1234567890abcdef0",
  "current_state": "running",
  "public_ip": "1.2.3.4",
  "action_requested": "status",
  "message": "Server is currently running"
}
```