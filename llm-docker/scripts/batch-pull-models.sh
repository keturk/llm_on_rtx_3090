#!/bin/bash
# Batch pull models for testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "📦 Batch Model Downloader"
echo ""

# Check if Ollama is running
if ! docker ps | grep -q ollama; then
    echo "❌ Ollama is not running. Starting it..."
    ./scripts/start-ollama.sh
    sleep 5
fi

# Model sets
declare -A MODEL_SETS
MODEL_SETS[small]="llama3.2:3b llama3.1:8b qwen2.5:7b gemma4:12b"
MODEL_SETS[medium]="qwen2.5:14b qwen3:14b deepseek-r1:14b phi3:14b gpt-oss:20b"
MODEL_SETS[large]="qwen3.6:27b gemma4:31b mistral-small3.2:24b qwen2.5:32b deepseek-r1:32b"
MODEL_SETS[coding]="qwen2.5-coder:14b devstral:24b devstral-small-2:24b qwen3.6:27b"
MODEL_SETS[agents]="gpt-oss:20b devstral:24b devstral-small-2:24b mistral-small3.2:24b gemma4:12b"
MODEL_SETS[2026]="gemma4:12b gpt-oss:20b gemma4:26b gemma4:31b mistral-small3.1:24b mistral-small3.2:24b devstral:24b devstral-small-2:24b qwen3.5:27b qwen3.6:27b qwen3.6:35b"
MODEL_SETS[all]="${MODEL_SETS[small]} ${MODEL_SETS[medium]} ${MODEL_SETS[large]} ${MODEL_SETS[coding]}"

# Parse arguments
SET="${1:-small}"

if [ -z "${MODEL_SETS[$SET]}" ]; then
    echo "Usage: $0 <set>"
    echo ""
    echo "Available sets:"
    echo "  small   - Quick testing (3-12B models)"
    echo "  medium  - Quality testing (14-20B models)"
    echo "  large   - Maximum quality (24-35B models)"
    echo "  coding  - Code-focused models (devstral, qwen3.6)"
    echo "  agents  - Agentic/tool-calling models (gpt-oss, devstral)"
    echo "  2026    - All new July 2026 models"
    echo "  all     - Small + medium + large + coding"
    echo ""
    echo "Example: $0 small"
    exit 1
fi

MODELS="${MODEL_SETS[$SET]}"

echo "Pulling models from '$SET' set:"
echo "$MODELS" | tr ' ' '\n' | sed 's/^/  - /'
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

echo ""
echo "🚀 Starting download..."
echo ""

# Find Ollama container dynamically
OLLAMA_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i ollama | head -1)
if [ -z "$OLLAMA_CONTAINER" ]; then
    echo "❌ Could not find Ollama container. Make sure it's running."
    exit 1
fi
echo "📦 Using container: $OLLAMA_CONTAINER"
echo ""

for MODEL in $MODELS; do
    echo "⬇️  Pulling $MODEL..."
    docker exec "$OLLAMA_CONTAINER" ollama pull "$MODEL"
    echo "✅ $MODEL downloaded"
    echo ""
done

echo "🎉 All models downloaded!"
echo ""
echo "List models:"
echo "  docker exec $OLLAMA_CONTAINER ollama list"
echo ""
echo "Test a model:"
echo "  docker exec -it $OLLAMA_CONTAINER ollama run llama3.2:3b"
