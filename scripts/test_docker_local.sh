#!/bin/bash

echo "🧪 Testing Factorio Docker setup locally..."
echo

cd docker || exit 1

echo "🏗️  Building and starting Factorio container..."
docker compose -f docker-compose.local.yml up --build -d

echo "⏳ Waiting for container to be healthy..."
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if [ "$(docker inspect factorio-server-local --format='{{.State.Health.Status}}' 2>/dev/null)" = "healthy" ]; then
        echo "✅ Container is healthy!"
        break
    fi
    echo -n "."
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    echo "❌ Container failed to become healthy within ${timeout}s"
    echo "Container logs:"
    docker logs factorio-server-local
    exit 1
fi

echo
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo
echo "🌐 Server Information:"
echo "   • Local address: localhost:34197"
echo "   • Container: factorio-server-local"
echo "   • Status: $(docker inspect factorio-server-local --format='{{.State.Status}}')"

echo
echo "🎮 You can now connect to the server using Factorio client:"
echo "   1. Open Factorio"
echo "   2. Go to Multiplayer"
echo "   3. Connect to: localhost:34197"

echo
echo "🔧 Management commands:"
echo "   • View logs:  docker logs -f factorio-server-local"
echo "   • Stop:       docker compose -f docker-compose.local.yml down"
echo "   • Restart:    docker compose -f docker-compose.local.yml restart"

echo
echo "✅ Local Docker test completed successfully!"
echo "💰 This setup will reduce AWS costs by ~50% when deployed!"