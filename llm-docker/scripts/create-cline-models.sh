#!/bin/bash
# Create custom models with larger context for Cline

set -e

CONTAINER_NAME="06f96dfcd4e3_ollama"

# Wait for Ollama to be ready
echo "Waiting for Ollama to be ready..."
until curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 2
done
echo "Ollama is ready!"

# Create qwen3-coder-cline with 64K context
echo "Creating qwen3-coder-cline with 64K context..."
docker exec "$CONTAINER_NAME" sh -c 'echo "FROM qwen3-coder:30b
PARAMETER num_ctx 65536" > /tmp/cline.modelfile && ollama create qwen3-coder-cline -f /tmp/cline.modelfile'

echo "✅ qwen3-coder-cline created"
docker exec "$CONTAINER_NAME" ollama list | grep cline
