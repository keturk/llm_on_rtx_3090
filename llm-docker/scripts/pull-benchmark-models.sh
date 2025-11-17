#!/bin/bash
# Download additional models for comprehensive benchmarking
# RTX 3090 24GB - All models selected to fit entirely on GPU

set -e

echo "=== Downloading Additional Models for RTX 3090 ==="
echo "These models are selected to run entirely on 24GB VRAM"
echo ""

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "❌ Ollama is not running. Start it first:"
    echo "   ./scripts/start-ollama.sh"
    exit 1
fi

echo "✅ Ollama is running"
echo ""

# Define models to download
declare -A MODELS
MODELS["mistral:7b"]="Well-rounded 7B model, fast and reliable"
MODELS["qwen2.5:7b"]="Strong coding & reasoning capabilities"
MODELS["phi3:14b"]="Microsoft's efficient model with 128k context"
MODELS["gemma2:27b"]="Google's high-quality 27B model (Q4 quantization)"
MODELS["codellama:34b"]="Meta's code-specialized model (Q4)"
MODELS["deepseek-coder:33b"]="Advanced coding model (Q4)"

# Show plan
echo "Models to download:"
echo "==================="
for model in "${!MODELS[@]}"; do
    size=$(docker exec ollama ollama show "$model" 2>/dev/null | grep "size" | head -1 || echo "")
    if docker exec ollama ollama list 2>/dev/null | grep -q "^${model}"; then
        echo "✅ $model - already installed"
    else
        echo "📥 $model - ${MODELS[$model]}"
    fi
done
echo ""

# Estimate total download size
echo "Estimated total download: ~60-80 GB"
echo "Estimated storage space needed: ~80-100 GB"
echo ""

read -p "Continue with download? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Download cancelled."
    exit 0
fi

echo ""
echo "Starting downloads..."
echo "====================="

FAILED_MODELS=()
SUCCESS_MODELS=()

for model in "${!MODELS[@]}"; do
    if docker exec ollama ollama list 2>/dev/null | grep -q "^${model}"; then
        echo ""
        echo "⏭️  Skipping $model (already installed)"
        SUCCESS_MODELS+=("$model")
        continue
    fi
    
    echo ""
    echo "📥 Downloading: $model"
    echo "   ${MODELS[$model]}"
    echo ""
    
    if docker exec -it ollama ollama pull "$model"; then
        echo "✅ Successfully downloaded $model"
        SUCCESS_MODELS+=("$model")
    else
        echo "❌ Failed to download $model"
        FAILED_MODELS+=("$model")
    fi
done

echo ""
echo "=== Download Summary ==="
echo ""

if [ ${#SUCCESS_MODELS[@]} -gt 0 ]; then
    echo "✅ Successfully installed/available:"
    for model in "${SUCCESS_MODELS[@]}"; do
        echo "   - $model"
    done
fi

if [ ${#FAILED_MODELS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed to download:"
    for model in "${FAILED_MODELS[@]}"; do
        echo "   - $model"
    done
fi

echo ""
echo "Current model inventory:"
docker exec ollama ollama list

echo ""
echo "Storage usage:"
df -h /mnt/llm-models 2>/dev/null || df -h / | head -2

echo ""
echo "=== Ready for benchmarking! ==="
echo "Run: ./scripts/comprehensive-benchmark.sh"
