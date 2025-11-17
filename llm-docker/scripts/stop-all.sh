#!/bin/bash
# Stop all LLM services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "🛑 Stopping all LLM services..."

# Stop all compose files
docker compose down 2>/dev/null || true
docker compose -f docker-compose.vllm.yml down 2>/dev/null || true
docker compose -f docker-compose.tgi.yml down 2>/dev/null || true

echo "✅ All services stopped"

# Show running containers (should be none)
echo ""
echo "Running LLM containers:"
docker ps --filter "name=ollama" --filter "name=vllm" --filter "name=tgi"
