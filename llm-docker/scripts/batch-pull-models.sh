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
MODEL_SETS[small]="llama3.2:3b llama3.1:8b qwen2.5:7b"
MODEL_SETS[medium]="llama3.1:8b-q4 qwen2.5:14b-q4 phi3:14b-q4"
MODEL_SETS[large]="llama3.1:70b-q2 qwen2.5:72b-q2"
MODEL_SETS[coding]="qwen2.5-coder:7b codellama:13b-q4"
MODEL_SETS[all]="${MODEL_SETS[small]} ${MODEL_SETS[medium]} ${MODEL_SETS[large]}"

# Parse arguments
SET="${1:-small}"

if [ -z "${MODEL_SETS[$SET]}" ]; then
    echo "Usage: $0 <set>"
    echo ""
    echo "Available sets:"
    echo "  small   - Quick testing (3-8B models)"
    echo "  medium  - Quality testing (14B Q4 models)"
    echo "  large   - Maximum quality (70B Q2 models)"
    echo "  coding  - Code-focused models"
    echo "  all     - All of the above"
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

for MODEL in $MODELS; do
    echo "⬇️  Pulling $MODEL..."
    docker exec ollama ollama pull "$MODEL"
    echo "✅ $MODEL downloaded"
    echo ""
done

echo "🎉 All models downloaded!"
echo ""
echo "List models:"
echo "  docker exec ollama ollama list"
echo ""
echo "Test a model:"
echo "  docker exec -it ollama ollama run llama3.2:3b"
