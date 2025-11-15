#!/bin/bash
# Start vLLM service with specified model

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Default model
MODEL="${1:-meta-llama/Llama-3.2-3B-Instruct}"

echo "🚀 Starting vLLM with model: $MODEL"

# Export model for docker-compose
export VLLM_MODEL="$MODEL"

# Stop existing vLLM if running
docker compose -f docker-compose.vllm.yml down 2>/dev/null || true

# Start vLLM with new model
docker compose -f docker-compose.vllm.yml up -d

echo "⏳ Waiting for vLLM to load model..."
sleep 10

# Check if vLLM is responding
if curl -s http://localhost:8000/v1/models > /dev/null; then
    echo "✅ vLLM is running!"
    echo ""
    echo "Model: $MODEL"
    echo "API endpoint: http://localhost:8000"
    echo ""
    echo "Test with:"
    echo "  curl http://localhost:8000/v1/models"
    echo "  ./scripts/test-model.sh vllm 'Hello, how are you?'"
else
    echo "❌ vLLM failed to start properly"
    docker compose -f docker-compose.vllm.yml logs
    exit 1
fi
