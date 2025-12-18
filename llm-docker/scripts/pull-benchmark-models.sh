#!/bin/bash
# Download all benchmark models for comprehensive testing
# RTX 3090 24GB - Updated December 2025
# Includes: 35+ models - DeepSeek-R1, Qwen3, Gemma3, Nemotron 3, Mistral Small 3, Ministral 3, Phi-4, QwQ

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
MODELS["granite3-dense:8b"]="🆕 IBM 128K context, ~5GB"
MODELS["dolphin3"]="🆕 Agentic/function calling, ~5GB"
MODELS["gemma3:4b"]="🆕 Multimodal, ~3GB"
MODELS["nemotron-mini:4b"]="🆕 RAG/function calling, ~3GB"
MODELS["ministral-3:3b"]="🆕 Edge agentic + vision, ~2GB"
MODELS["phi3.5"]="🆕 Microsoft 3.8B, ~2.5GB"
MODELS["phi4-mini"]="🆕 Compact reasoning 128K, ~2.5GB"
MODELS["granite3.1-moe:3b"]="🆕 IBM MoE 40 experts, ~2GB"

# Medium models (8-14B) - Balanced
MODELS["ministral-3:8b"]="🆕 Agentic + vision, ~5GB"
MODELS["phi3:14b"]="Microsoft, 128k context, ~8GB"
MODELS["phi4"]="🆕 Advanced reasoning, ~9GB"
MODELS["qwen2.5:14b"]="Production quality, ~9GB"
MODELS["qwen3:14b"]="🆕 Excellent quality, ~9GB"
MODELS["deepseek-r1:14b"]="🆕 Best reasoning value, ~9GB"
MODELS["gemma3:12b"]="🆕 Multimodal balanced, ~8GB"
MODELS["qwen2.5-coder:14b"]="Coding specialist, ~9GB"
MODELS["ministral-3:14b"]="🆕 Advanced agentic + vision, ~9GB"
MODELS["codestral:22b"]="🆕 Mistral coding specialist, ~13GB"

# Large models (24-34B) - Maximum quality
MODELS["mistral-small:24b"]="🆕 Best sub-70B, ~14GB"
MODELS["gemma2:27b"]="Google high-quality, ~15GB"
MODELS["gemma3:27b"]="🆕 Multimodal large, ~17GB"
MODELS["qwen3:30b-a3b"]="🆕 MoE fast inference, ~18GB"
MODELS["qwen3-coder:30b"]="🆕 Qwen3 coding MoE 256K, ~19GB"
MODELS["nemotron-3-nano:30b"]="🆕 Agentic MoE 1M context, ~24GB"
MODELS["qwen2.5:32b"]="Maximum general quality, ~21GB"
MODELS["qwq:32b"]="🆕 Qwen reasoning specialist, ~20GB"
MODELS["deepseek-r1:32b"]="🆕 Best reasoning quality, ~19GB"
MODELS["codellama:34b"]="Meta code specialist, ~18GB"
MODELS["deepseek-coder:33b"]="Advanced coding, ~17GB"

# Model order for display
MODEL_ORDER=(
    # Small (3-8B)
    "llama3.2:3b" "llama3.1:8b" "mistral:7b" "qwen2.5:7b" "qwen3:8b" "deepseek-r1:8b" "granite3-dense:8b" "dolphin3" "gemma3:4b" "nemotron-mini:4b" "ministral-3:3b" "phi3.5" "phi4-mini" "granite3.1-moe:3b"
    # Medium (8-14B)
    "ministral-3:8b" "phi3:14b" "phi4" "qwen2.5:14b" "qwen3:14b" "deepseek-r1:14b" "gemma3:12b" "qwen2.5-coder:14b" "ministral-3:14b" "codestral:22b"
    # Large (24-34B)
    "mistral-small:24b" "gemma2:27b" "gemma3:27b" "qwen3:30b-a3b" "qwen3-coder:30b" "nemotron-3-nano:30b" "qwen2.5:32b" "qwq:32b" "deepseek-r1:32b" "codellama:34b" "deepseek-coder:33b"
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
echo "Run: ./scripts/run-full-benchmark.sh"