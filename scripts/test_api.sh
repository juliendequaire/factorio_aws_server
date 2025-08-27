#!/bin/bash

# Change to infrastructure directory and get API Gateway URL from Terraform output
cd infrastructure
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")

if [ -z "$API_URL" ]; then
    echo "❌ Could not get API Gateway URL. Make sure Terraform has been applied successfully."
    exit 1
fi

# Remove the trailing /server and add proper endpoints
BASE_URL=$(echo $API_URL | sed 's|/server$||')

echo "🧪 Testing Factorio Server API..."
echo "Base URL: $BASE_URL"
echo

# Test status endpoint
echo "📊 Testing status endpoint..."
curl -X POST "$BASE_URL/server/status" \
     -H "Content-Type: application/json" \
     -w "\nHTTP Status: %{http_code}\n\n"

# Test start endpoint
echo "▶️  Testing start endpoint..."
curl -X POST "$BASE_URL/server/start" \
     -H "Content-Type: application/json" \
     -w "\nHTTP Status: %{http_code}\n\n"

# Wait a moment
echo "⏳ Waiting 5 seconds..."
sleep 5

# Test status again
echo "📊 Testing status endpoint again..."
curl -X POST "$BASE_URL/server/status" \
     -H "Content-Type: application/json" \
     -w "\nHTTP Status: %{http_code}\n\n"

# Test stop endpoint
echo "⏹️  Testing stop endpoint..."
curl -X POST "$BASE_URL/server/stop" \
     -H "Content-Type: application/json" \
     -w "\nHTTP Status: %{http_code}\n\n"

echo "✅ API testing complete!"