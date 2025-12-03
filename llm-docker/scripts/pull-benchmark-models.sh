#!/bin/bash
# Download all benchmark models for comprehensive testing
# RTX 3090 24GB - Updated December 2025
# Includes: Original models + DeepSeek-R1, Qwen3, Gemma3

echo "=== Downloading Benchmark Models for RTX 3090 (2025 Edition) ==="
echo "All models selected to run entirely on 24GB VRAM"
echo ""

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "❌ Ollama is not running. Start it first:"
    echo "   ./scripts/start-ollama.sh"
    exit 1
fi

echo "✅ Ollama is running"
echo ""

# Define all benchmark models (ordered by category and size)
declare -A MODELS

# Small models (3-8B) - Fast
MODELS["llama3.2:3b"]="Fast baseline, ~2GB"
MODELS["llama3.1:8b"]="Daily driver, ~5GB"
MODELS["mistral:7b"]="General use, ~4GB"
MODELS["qwen2.5:7b"]="Coding & reasoning, ~5GB"
MODELS["qwen3:8b"]="🆕 Next-gen Qwen, ~5GB"
MODELS["deepseek-r1:8b"]="🆕 Reasoning model, ~5GB"
MODELS["gemma3:4b"]="🆕 Multimodal, ~3GB"

# Medium models (12-14B) - Balanced
MODELS["phi3:14b"]="Microsoft, 128k context, ~8GB"
MODELS["qwen2.5:14b"]="Production quality, ~9GB"
MODELS["qwen3:14b"]="🆕 Excellent quality, ~9GB"
MODELS["deepseek-r1:14b"]="🆕 Best reasoning value, ~9GB"
MODELS["gemma3:12b"]="🆕 Multimodal balanced, ~8GB"
MODELS["qwen2.5-coder:14b"]="Coding specialist, ~9GB"

# Large models (27-34B) - Maximum quality
MODELS["gemma2:27b"]="Google high-quality, ~15GB"
MODELS["gemma3:27b"]="🆕 Multimodal large, ~17GB"
MODELS["qwen3:30b-a3b"]="🆕 MoE fast inference, ~18GB"
MODELS["qwen2.5:32b"]="Maximum general quality, ~19GB"
MODELS["deepseek-r1:32b"]="🆕 Best reasoning quality, ~19GB"
MODELS["codellama:34b"]="Meta code specialist, ~19GB"
MODELS["deepseek-coder:33b"]="Advanced coding, ~18GB"

# Model order for display
MODEL_ORDER=(
    "llama3.2:3b" "llama3.1:8b" "mistral:7b" "qwen2.5:7b" "qwen3:8b" "deepseek-r1:8b" "gemma3:4b"
    "phi3:14b" "qwen2.5:14b" "qwen3:14b" "deepseek-r1:14b" "gemma3:12b" "qwen2.5-coder:14b"
    "gemma2:27b" "gemma3:27b" "qwen3:30b-a3b" "qwen2.5:32b" "deepseek-r1:32b" "codellama:34b" "deepseek-coder:33b"
)

# Show current status
echo "Model Status:"
echo "============="
MISSING_MODELS=()
INSTALLED_COUNT=0

# Get the list of installed models once
INSTALLED_LIST=$(docker exec ollama ollama list 2>/dev/null || echo "")

for model in "${MODEL_ORDER[@]}"; do
    desc="${MODELS[$model]}"
    if echo "$INSTALLED_LIST" | grep -q "^${model}"; then
        echo "✅ $model - $desc"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        echo "📥 $model - $desc (needs download)"
        MISSING_MODELS+=("$model")
    fi
done

echo ""
echo "Installed: $INSTALLED_COUNT/${#MODEL_ORDER[@]} models"
echo "To download: ${#MISSING_MODELS[@]} models"
echo ""

if [ ${#MISSING_MODELS[@]} -eq 0 ]; then
    echo "✅ All benchmark models are already installed!"
    echo ""
    docker exec ollama ollama list
    exit 0
fi

# Calculate total download size
echo "Estimated total download: ~$(( ${#MISSING_MODELS[@]} * 8 )) GB (varies by model)"
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
echo "Run: ./scripts/comprehensive-benchmark-2025.sh"