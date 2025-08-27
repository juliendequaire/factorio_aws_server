#!/usr/bin/env python3
"""
Local API server to simulate AWS API Gateway + Lambda for Factorio server management
"""
import json
import subprocess
import time
from flask import Flask, request, jsonify
from flask_cors import CORS
import docker
import os

app = Flask(__name__)
CORS(app)

# Docker client
try:
    docker_client = docker.from_env()
except Exception as e:
    print(f"Warning: Docker client initialization failed: {e}")
    docker_client = None

CONTAINER_NAME = "factorio-server-local"
COMPOSE_FILE = "docker-compose.local.yml"

def get_container_status():
    """Get the status of the Factorio Docker container"""
    if not docker_client:
        return {"status": "error", "message": "Docker client not available"}
    
    try:
        container = docker_client.containers.get(CONTAINER_NAME)
        return {
            "status": container.status,
            "health": container.attrs.get("State", {}).get("Health", {}).get("Status", "unknown"),
            "ports": container.ports,
            "created": container.attrs.get("Created"),
            "started": container.attrs.get("State", {}).get("StartedAt")
        }
    except docker.errors.NotFound:
        return {"status": "not_found", "message": "Container not found"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def run_docker_compose_command(action):
    """Run docker-compose commands"""
    try:
        os.chdir("/Users/jdequaire/Dev/factorio_aws_server/docker")
        cmd = ["docker", "compose", "-f", COMPOSE_FILE, action]
        if action == "up":
            cmd.extend(["-d"])
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        return {
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "error": "Command timed out"}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "factorio-local-api"})

@app.route('/server/<action>', methods=['POST'])
def manage_server(action):
    """Manage Factorio server - simulate API Gateway + Lambda"""
    
    # Validate action
    if action not in ['start', 'stop', 'status', 'restart']:
        return jsonify({
            'error': 'Invalid action. Use start, stop, status, or restart'
        }), 400
    
    # Get current container status
    container_info = get_container_status()
    
    result = {
        'action_requested': action,
        'container_name': CONTAINER_NAME,
        'container_status': container_info.get('status', 'unknown'),
        'container_health': container_info.get('health', 'unknown'),
        'local_api': True,
        'timestamp': time.time()
    }
    
    try:
        if action == 'status':
            result['message'] = f"Container status: {container_info.get('status', 'unknown')}"
            result['details'] = container_info
            
        elif action == 'start':
            if container_info.get('status') in ['running']:
                result['message'] = 'Container is already running'
            else:
                # Start the container
                compose_result = run_docker_compose_command('up')
                if compose_result['success']:
                    result['message'] = 'Start command sent. Server will be available shortly.'
                    result['container_status'] = 'starting'
                else:
                    result['message'] = f"Failed to start container: {compose_result.get('error', 'Unknown error')}"
                    result['error'] = compose_result
                    
        elif action == 'stop':
            if container_info.get('status') not in ['running']:
                result['message'] = 'Container is not running'
            else:
                # Stop the container
                compose_result = run_docker_compose_command('down')
                if compose_result['success']:
                    result['message'] = 'Stop command sent. Server is shutting down.'
                    result['container_status'] = 'stopping'
                else:
                    result['message'] = f"Failed to stop container: {compose_result.get('error', 'Unknown error')}"
                    result['error'] = compose_result
                    
        elif action == 'restart':
            # Restart the container
            stop_result = run_docker_compose_command('down')
            if stop_result['success']:
                time.sleep(2)  # Brief pause
                start_result = run_docker_compose_command('up')
                if start_result['success']:
                    result['message'] = 'Restart command sent. Server will be available shortly.'
                    result['container_status'] = 'restarting'
                else:
                    result['message'] = f"Failed to restart container: {start_result.get('error', 'Unknown error')}"
                    result['error'] = start_result
            else:
                result['message'] = f"Failed to stop container for restart: {stop_result.get('error', 'Unknown error')}"
                result['error'] = stop_result
        
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({
            'error': str(e),
            'message': 'Internal server error',
            'action_requested': action
        }), 500

@app.route('/server/logs', methods=['GET'])
def get_server_logs():
    """Get Factorio server logs"""
    try:
        if not docker_client:
            return jsonify({"error": "Docker client not available"}), 500
        
        container = docker_client.containers.get(CONTAINER_NAME)
        logs = container.logs(tail=100).decode('utf-8')
        
        return jsonify({
            "logs": logs,
            "container": CONTAINER_NAME,
            "timestamp": time.time()
        }), 200
        
    except docker.errors.NotFound:
        return jsonify({"error": "Container not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/info', methods=['GET'])
def get_info():
    """Get API and server information"""
    container_info = get_container_status()
    
    return jsonify({
        "api": {
            "name": "Factorio Local API",
            "version": "1.0.0",
            "endpoints": [
                "POST /server/start",
                "POST /server/stop", 
                "POST /server/status",
                "POST /server/restart",
                "GET /server/logs",
                "GET /info",
                "GET /health"
            ]
        },
        "factorio": {
            "container_name": CONTAINER_NAME,
            "compose_file": COMPOSE_FILE,
            "local_port": "34197",
            "local_address": "localhost:34197"
        },
        "container": container_info
    }), 200

if __name__ == '__main__':
    print("🚀 Starting Factorio Local API Server...")
    print("📍 API will be available at: http://localhost:5000")
    print("🎮 Factorio server will be available at: localhost:34197")
    print()
    print("Available endpoints:")
    print("  POST http://localhost:5000/server/start")
    print("  POST http://localhost:5000/server/stop")
    print("  POST http://localhost:5000/server/status")
    print("  POST http://localhost:5000/server/restart")
    print("  GET  http://localhost:5000/server/logs")
    print("  GET  http://localhost:5000/info")
    print("  GET  http://localhost:5000/health")
    print()
    
    app.run(host='0.0.0.0', port=5000, debug=True)