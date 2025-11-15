#!/bin/bash
# Start Ollama service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "🚀 Starting Ollama..."
docker compose up -d

echo "⏳ Waiting for Ollama to be ready..."
sleep 5

# Check if Ollama is responding
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama is running!"
    echo ""
    echo "Available commands:"
    echo "  docker exec -it ollama ollama list                    # List installed models"
    echo "  docker exec -it ollama ollama pull llama3.2:3b        # Pull a model"
    echo "  docker exec -it ollama ollama run llama3.2:3b         # Run a model interactively"
    echo ""
    echo "API endpoint: http://localhost:11434"
else
    echo "❌ Ollama failed to start properly"
    docker compose logs ollama
    exit 1
fi
