import json
import boto3
import os
from typing import Dict, Any

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function to control Factorio EC2 instance
    """
    try:
        # Initialize EC2 client
        ec2 = boto3.client('ec2')
        instance_id = os.environ['INSTANCE_ID']
        
        # Extract action from path parameters
        action = event.get('pathParameters', {}).get('action', '').lower()
        
        if action not in ['start', 'stop', 'status']:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Invalid action. Use start, stop, or status'
                })
            }
        
        # Get current instance state
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        current_state = instance['State']['Name']
        
        result = {
            'instance_id': instance_id,
            'current_state': current_state,
            'public_ip': instance.get('PublicIpAddress', 'N/A'),
            'action_requested': action
        }
        
        if action == 'status':
            result['message'] = f'Server is currently {current_state}'
            
        elif action == 'start':
            if current_state in ['stopped', 'stopping']:
                ec2.start_instances(InstanceIds=[instance_id])
                result['message'] = 'Start command sent. Server will be available shortly.'
            else:
                result['message'] = f'Server is already {current_state}'
                
        elif action == 'stop':
            if current_state in ['running', 'pending']:
                ec2.stop_instances(InstanceIds=[instance_id])
                result['message'] = 'Stop command sent. Server is shutting down.'
            else:
                result['message'] = f'Server is already {current_state}'
        
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