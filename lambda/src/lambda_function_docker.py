import json
import boto3
import os
import time
from typing import Dict, Any

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function to control Factorio Docker container on EC2 instance
    """
    try:
        # Initialize EC2 and SSM clients
        ec2 = boto3.client('ec2')
        ssm = boto3.client('ssm')
        instance_id = os.environ['INSTANCE_ID']
        
        # Extract action from path parameters
        action = event.get('pathParameters', {}).get('action', '').lower()
        
        if action not in ['start', 'stop', 'status', 'restart']:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Invalid action. Use start, stop, status, or restart'
                })
            }
        
        # Get current instance state
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        ec2_state = instance['State']['Name']
        
        result = {
            'instance_id': instance_id,
            'ec2_state': ec2_state,
            'public_ip': instance.get('PublicIpAddress', 'N/A'),
            'action_requested': action
        }
        
        # If EC2 is not running, handle accordingly
        if ec2_state not in ['running']:
            if action == 'start':
                if ec2_state in ['stopped', 'stopping']:
                    ec2.start_instances(InstanceIds=[instance_id])
                    result['message'] = 'EC2 instance starting. Container will start automatically once EC2 is ready.'
                    result['container_status'] = 'pending'
                else:
                    result['message'] = f'EC2 instance is {ec2_state}. Cannot start container.'
                    result['container_status'] = 'unavailable'
            else:
                result['message'] = f'EC2 instance is {ec2_state}. Container operations not available.'
                result['container_status'] = 'unavailable'
                
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps(result)
            }
        
        # EC2 is running, manage Docker container
        try:
            if action == 'status':
                # Check container status
                status_response = ssm.send_command(
                    InstanceIds=[instance_id],
                    DocumentName='AWS-RunShellScript',
                    Parameters={
                        'commands': [
                            'cd /opt/factorio-docker',
                            'docker compose ps --format json'
                        ]
                    }
                )
                
                # Wait for command to complete and get result
                command_id = status_response['Command']['CommandId']
                time.sleep(2)  # Give command time to execute
                
                output_response = ssm.get_command_invocation(
                    CommandId=command_id,
                    InstanceId=instance_id
                )
                
                stdout = output_response.get('StandardOutput', '')
                container_status = _parse_container_status(stdout)
                
                result['container_status'] = container_status
                result['message'] = f'EC2 running, container status: {container_status}'
                
            elif action == 'start':
                # Start container
                start_response = ssm.send_command(
                    InstanceIds=[instance_id],
                    DocumentName='AWS-RunShellScript',
                    Parameters={
                        'commands': [
                            'cd /opt/factorio-docker',
                            './start.sh'
                        ]
                    }
                )
                
                result['container_status'] = 'starting'
                result['message'] = 'Container start command sent. Server will be available shortly.'
                
            elif action == 'stop':
                # Stop container
                stop_response = ssm.send_command(
                    InstanceIds=[instance_id],
                    DocumentName='AWS-RunShellScript',
                    Parameters={
                        'commands': [
                            'cd /opt/factorio-docker',
                            './stop.sh'
                        ]
                    }
                )
                
                result['container_status'] = 'stopping'
                result['message'] = 'Container stop command sent.'
                
            elif action == 'restart':
                # Restart container
                restart_response = ssm.send_command(
                    InstanceIds=[instance_id],
                    DocumentName='AWS-RunShellScript',
                    Parameters={
                        'commands': [
                            'cd /opt/factorio-docker',
                            './stop.sh',
                            'sleep 5',
                            './start.sh'
                        ]
                    }
                )
                
                result['container_status'] = 'restarting'
                result['message'] = 'Container restart command sent.'
                
        except Exception as ssm_error:
            result['message'] = f'Container management failed: {str(ssm_error)}'
            result['container_status'] = 'error'
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(result)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Internal server error'
            })
        }

def _parse_container_status(docker_output: str) -> str:
    """
    Parse docker compose ps output to determine container status
    """
    try:
        if not docker_output.strip():
            return 'stopped'
            
        # Look for common status indicators
        output_lower = docker_output.lower()
        
        if 'up' in output_lower and 'healthy' in output_lower:
            return 'running'
        elif 'up' in output_lower:
            return 'starting'
        elif 'exit' in output_lower or 'exited' in output_lower:
            return 'stopped'
        else:
            return 'unknown'
            
    except Exception:
        return 'unknown'