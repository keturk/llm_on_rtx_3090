#!/bin/bash
# Download all benchmark models for comprehensive testing
# RTX 3090 24GB - All models selected to run entirely on GPU

echo "=== Downloading Benchmark Models for RTX 3090 ==="
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

# Define all benchmark models (ordered by size)
declare -A MODELS
MODELS["llama3.2:3b"]="Fast baseline, quick responses"
MODELS["llama3.1:8b"]="Daily driver, well-rounded"
MODELS["mistral:7b"]="General use, fast and reliable"
MODELS["qwen2.5:7b"]="Strong coding & reasoning"
MODELS["phi3:14b"]="Microsoft's efficient model, 128k context"
MODELS["qwen2.5:14b"]="Production quality, excellent balance"
MODELS["gemma2:27b"]="Google's high-quality 27B model"
MODELS["qwen2.5:32b"]="Maximum quality for general tasks"
MODELS["codellama:34b"]="Meta's code-specialized model"
MODELS["deepseek-coder:33b"]="Advanced coding model"

# Show current status
echo "Model Status:"
echo "============="
MISSING_MODELS=()
INSTALLED_COUNT=0

# Get the list of installed models once
INSTALLED_LIST=$(docker exec ollama ollama list 2>/dev/null || echo "")

for model in "llama3.2:3b" "llama3.1:8b" "mistral:7b" "qwen2.5:7b" "phi3:14b" "qwen2.5:14b" "gemma2:27b" "qwen2.5:32b" "codellama:34b" "deepseek-coder:33b"; do
    if echo "$INSTALLED_LIST" | grep -q "^${model}"; then
        echo "✅ $model - installed"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        echo "📥 $model - needs download"
        MISSING_MODELS+=("$model")
    fi
done

echo ""
echo "Installed: $INSTALLED_COUNT/10 models"
echo "To download: ${#MISSING_MODELS[@]} models"
echo ""

if [ ${#MISSING_MODELS[@]} -eq 0 ]; then
    echo "✅ All benchmark models are already installed!"
    echo ""
    docker exec ollama ollama list
    exit 0
fi

# Estimate download sizes
echo "Estimated download sizes:"
for model in "${MISSING_MODELS[@]}"; do
    case $model in
        "llama3.2:3b") echo "  $model: ~2 GB" ;;
        "llama3.1:8b") echo "  $model: ~4.7 GB" ;;
        "mistral:7b") echo "  $model: ~4 GB" ;;
        "qwen2.5:7b") echo "  $model: ~4.7 GB" ;;
        "phi3:14b") echo "  $model: ~7.9 GB" ;;
        "qwen2.5:14b") echo "  $model: ~9 GB" ;;
        "gemma2:27b") echo "  $model: ~16 GB" ;;
        "qwen2.5:32b") echo "  $model: ~19 GB" ;;
        "codellama:34b") echo "  $model: ~19 GB" ;;
        "deepseek-coder:33b") echo "  $model: ~19 GB" ;;
    esac
done
echo ""

read -p "Download ${#MISSING_MODELS[@]} missing model(s)? (y/N) " -n 1 -r
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

for model in "${MISSING_MODELS[@]}"; do
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
    echo "✅ Successfully downloaded:"
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