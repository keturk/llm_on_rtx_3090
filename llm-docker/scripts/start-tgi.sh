#!/bin/bash
# Start Text Generation Inference service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

MODEL="${1:-meta-llama/Llama-3.2-3B-Instruct}"

echo "🚀 Starting TGI with model: $MODEL"

# Update environment variable
export TGI_MODEL="$MODEL"

# Stop existing TGI if running
docker compose -f docker-compose.tgi.yml down 2>/dev/null || true

# Start TGI
docker compose -f docker-compose.tgi.yml up -d

echo "⏳ Waiting for TGI to load model (this may take a while)..."
sleep 15

# Check if TGI is responding
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ TGI is running!"
    echo ""
    echo "Model: $MODEL"
    echo "API endpoint: http://localhost:8080"
    echo ""
    echo "Test with:"
    echo "  curl http://localhost:8080/health"
    echo "  ./scripts/test-model.sh tgi 'Hello, how are you?'"
else
    echo "❌ TGI failed to start properly"
    docker compose -f docker-compose.tgi.yml logs
    exit 1
fi
