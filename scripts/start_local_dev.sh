#!/bin/bash

set -e

echo "🔧 Starting Factorio Local Development Environment..."
echo

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if required files exist
if [ ! -f "docker-compose.full.yml" ]; then
    echo "❌ docker-compose.full.yml not found. Please run from project root."
    exit 1
fi

echo "🏗️  Building and starting services..."
docker-compose -f docker-compose.full.yml up --build -d

echo "⏳ Waiting for services to be ready..."

# Wait for API health check
timeout=60
counter=0
echo -n "   Checking API health"
while [ $counter -lt $timeout ]; do
    if curl -s http://localhost:5001/health >/dev/null 2>&1; then
        echo " ✅"
        break
    fi
    echo -n "."
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    echo " ❌"
    echo "API failed to start within ${timeout}s"
    exit 1
fi

# Wait for Factorio container health
echo -n "   Checking Factorio health"
counter=0
while [ $counter -lt $timeout ]; do
    health_status=$(docker inspect factorio-server-local --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    if [ "$health_status" = "healthy" ]; then
        echo " ✅"
        break
    fi
    echo -n "."
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    echo " ❌"
    echo "Factorio container failed to become healthy"
fi

echo
echo "📊 Services Status:"
docker-compose -f docker-compose.full.yml ps

echo
echo "🌐 Local Development Environment Ready!"
echo
echo "📍 Service URLs:"
echo "   • API Server:      http://localhost:5001"
echo "   • API Health:      http://localhost:5001/health"
echo "   • API Info:        http://localhost:5001/info"
echo "   • Factorio Server: localhost:34197 (UDP)"
echo
echo "🔧 Management Commands:"
echo "   • Test API:        ./scripts/test_api_local.sh"
echo "   • View logs:       docker-compose -f docker-compose.full.yml logs -f"
echo "   • Stop services:   docker-compose -f docker-compose.full.yml down"
echo
echo "📡 Example API Calls:"
echo "   curl http://localhost:5001/health"
echo "   curl -X POST http://localhost:5001/server/status"
echo "   curl -X POST http://localhost:5001/server/start"
echo "   curl -X POST http://localhost:5001/server/stop"
echo
echo "🎮 Connect to Factorio:"
echo "   1. Open Factorio game client"
echo "   2. Go to Multiplayer"
echo "   3. Connect to: localhost:34197"
echo
echo "✅ Development environment started successfully!"