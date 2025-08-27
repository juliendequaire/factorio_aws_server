#!/bin/bash

set -e

echo "🧪 Testing Factorio Local API Gateway..."
echo

API_BASE="http://localhost:5001"

# Function to make API calls and show results
test_endpoint() {
    local endpoint="$1"
    local method="$2"
    local description="$3"
    
    echo "📡 Testing: $description"
    echo "   Endpoint: $method $API_BASE$endpoint"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$API_BASE$endpoint")
    else
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" "$API_BASE$endpoint" -H "Content-Type: application/json")
    fi
    
    http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
    body=$(echo "$response" | sed '$d')
    
    echo "   Status: $http_code"
    if [ "$http_code" = "200" ]; then
        echo "   ✅ Success"
    else
        echo "   ❌ Failed"
    fi
    
    # Pretty print JSON if it's valid
    if echo "$body" | jq . >/dev/null 2>&1; then
        echo "   Response:"
        echo "$body" | jq . | sed 's/^/     /'
    else
        echo "   Response: $body"
    fi
    
    echo
    sleep 1
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local url="$2"
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            echo "✅ $service_name is ready!"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "❌ $service_name failed to start within expected time"
    return 1
}

# Start the full stack
echo "🚀 Starting Factorio + API stack..."
docker-compose -f docker-compose.full.yml up --build -d

# Wait for API to be ready
if ! wait_for_service "API Server" "$API_BASE/health"; then
    echo "❌ API server failed to start"
    exit 1
fi

echo
echo "📊 Services Status:"
docker-compose -f docker-compose.full.yml ps

echo
echo "🔍 Testing API Endpoints..."
echo

# Test health endpoint
test_endpoint "/health" "GET" "Health Check"

# Test info endpoint
test_endpoint "/info" "GET" "Server Information"

# Test status endpoint
test_endpoint "/server/status" "POST" "Server Status"

# Test start endpoint
test_endpoint "/server/start" "POST" "Start Server"

# Wait for server to start
echo "⏳ Waiting for Factorio server to fully start..."
sleep 10

# Test status again
test_endpoint "/server/status" "POST" "Server Status (after start)"

# Test logs endpoint
test_endpoint "/server/logs" "GET" "Server Logs"

# Test restart endpoint
test_endpoint "/server/restart" "POST" "Restart Server"

# Wait for restart
echo "⏳ Waiting for server restart..."
sleep 10

# Final status check
test_endpoint "/server/status" "POST" "Final Status Check"

# Test stop endpoint
test_endpoint "/server/stop" "POST" "Stop Server"

# Wait for stop
echo "⏳ Waiting for server to stop..."
sleep 5

# Final status check
test_endpoint "/server/status" "POST" "Status After Stop"

echo "🎯 Testing Complete!"
echo
echo "💡 You can also test manually:"
echo "   • API: $API_BASE"
echo "   • Factorio: localhost:34197 (when running)"
echo
echo "🧹 To clean up:"
echo "   docker-compose -f docker-compose.full.yml down"