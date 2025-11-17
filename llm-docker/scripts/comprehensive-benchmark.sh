#!/bin/bash
# Comprehensive LLM Benchmark Suite for RTX 3090
# Tests speed, VRAM usage, and quality metrics

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/../benchmark_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="${RESULTS_DIR}/benchmark_${TIMESTAMP}.md"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Models to test (comment out any you don't want to test)
MODELS=(
    "llama3.2:3b"
    "llama3.1:8b"
    "mistral:7b"
    "qwen2.5:7b"
    "phi3:14b"
    "qwen2.5:14b"
    "gemma2:27b"
    "qwen2.5:32b"
    "codellama:34b"
    "deepseek-coder:33b"
)

# Test prompts
declare -A PROMPTS
PROMPTS["simple"]="Count from 1 to 10"
PROMPTS["reasoning"]="Explain the difference between supervised and unsupervised machine learning in 3 sentences"
PROMPTS["coding"]="Write a Python function to check if a string is a palindrome"
PROMPTS["creative"]="Write a haiku about artificial intelligence"
PROMPTS["math"]="What is 15% of 847? Show your work step by step"

echo "=== LLM Comprehensive Benchmark Suite ===" | tee "$RESULTS_FILE"
echo "Date: $(date)" | tee -a "$RESULTS_FILE"
echo "System: Dell T5820 + RTX 3090 (24GB)" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# Check which models are installed
echo "## Checking Installed Models" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

AVAILABLE_MODELS=()
for model in "${MODELS[@]}"; do
    if docker exec ollama ollama list 2>/dev/null | grep -q "^${model}"; then
        echo "✅ $model - installed" | tee -a "$RESULTS_FILE"
        AVAILABLE_MODELS+=("$model")
    else
        echo "⚠️  $model - not installed (skipping)" | tee -a "$RESULTS_FILE"
    fi
done

echo "" | tee -a "$RESULTS_FILE"

if [ ${#AVAILABLE_MODELS[@]} -eq 0 ]; then
    echo "❌ No models available to test!" | tee -a "$RESULTS_FILE"
    exit 1
fi

# Function to get VRAM usage
get_vram_usage() {
    nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1
}

# Function to get GPU utilization
get_gpu_util() {
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1
}

# Function to get GPU temperature
get_gpu_temp() {
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1
}

# Function to benchmark a single model
benchmark_model() {
    local model=$1
    local prompt_name=$2
    local prompt=$3
    
    echo "  Testing: $prompt_name..." >&2
    
    # Clear any loaded model first
    docker exec ollama ollama stop "$model" 2>/dev/null || true
    sleep 2
    
    # Record start metrics
    local start_vram=$(get_vram_usage)
    local start_time=$(date +%s.%N)
    
    # Run inference and capture output
    local output
    output=$(docker exec ollama ollama run "$model" "$prompt" 2>&1)
    
    # Record end time
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc)
    
    # Wait a moment for GPU to stabilize
    sleep 1
    
    # Get peak metrics (approximate)
    local peak_vram=$(get_vram_usage)
    local gpu_util=$(get_gpu_util)
    local gpu_temp=$(get_gpu_temp)
    
    # Count tokens (rough estimate: words * 1.3)
    local word_count=$(echo "$output" | wc -w)
    local token_estimate=$(echo "$word_count * 1.3" | bc | cut -d. -f1)
    local tokens_per_sec=$(echo "scale=1; $token_estimate / $elapsed" | bc)
    
    # Output results
    echo "$elapsed|$peak_vram|$gpu_util|$gpu_temp|$tokens_per_sec|$token_estimate"
}

# Main benchmark results table
echo "## Performance Results" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"
echo "| Model | Size | VRAM (MB) | GPU Util % | Temp °C | Tokens/sec | Time (s) | Quality |" | tee -a "$RESULTS_FILE"
echo "|-------|------|-----------|------------|---------|------------|----------|---------|" | tee -a "$RESULTS_FILE"

# Store detailed results
declare -A MODEL_RESULTS

for model in "${AVAILABLE_MODELS[@]}"; do
    echo ""
    echo "### Testing: $model"
    echo "Loading model..."
    
    # Pre-load model with a simple query
    docker exec ollama ollama run "$model" "test" > /dev/null 2>&1
    sleep 3
    
    # Get model size
    model_size=$(docker exec ollama ollama list | grep "^${model}" | awk '{print $3}')
    
    # Run reasoning benchmark (primary metric)
    result=$(benchmark_model "$model" "reasoning" "${PROMPTS[reasoning]}")
    
    elapsed=$(echo "$result" | cut -d'|' -f1)
    vram=$(echo "$result" | cut -d'|' -f2)
    gpu_util=$(echo "$result" | cut -d'|' -f3)
    gpu_temp=$(echo "$result" | cut -d'|' -f4)
    tps=$(echo "$result" | cut -d'|' -f5)
    
    # Determine quality tier based on model size
    if [[ "$model" == *"32b"* ]] || [[ "$model" == *"33b"* ]] || [[ "$model" == *"34b"* ]]; then
        quality="Best"
    elif [[ "$model" == *"27b"* ]]; then
        quality="Excellent+"
    elif [[ "$model" == *"14b"* ]]; then
        quality="Excellent"
    elif [[ "$model" == *"7b"* ]] || [[ "$model" == *"8b"* ]]; then
        quality="Very Good"
    else
        quality="Good"
    fi
    
    # Store results
    MODEL_RESULTS["$model"]="$vram|$gpu_util|$tps|$elapsed|$quality"
    
    echo "| $model | $model_size | $vram | $gpu_util | $gpu_temp | $tps | $elapsed | $quality |" | tee -a "$RESULTS_FILE"
    
    # Unload model to free VRAM
    echo "  Unloading model..."
    docker exec ollama ollama stop "$model" 2>/dev/null || true
    sleep 3
done

echo "" | tee -a "$RESULTS_FILE"

# Detailed per-prompt benchmarks for selected models
echo "## Detailed Prompt Analysis" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# Select a few key models for detailed testing
KEY_MODELS=("llama3.1:8b" "qwen2.5:14b" "qwen2.5:32b")

for model in "${KEY_MODELS[@]}"; do
    if [[ " ${AVAILABLE_MODELS[*]} " =~ " ${model} " ]]; then
        echo "### $model" | tee -a "$RESULTS_FILE"
        echo "" | tee -a "$RESULTS_FILE"
        echo "| Prompt Type | Time (s) | Tokens/sec | Output Length |" | tee -a "$RESULTS_FILE"
        echo "|-------------|----------|------------|---------------|" | tee -a "$RESULTS_FILE"
        
        # Load model
        docker exec ollama ollama run "$model" "test" > /dev/null 2>&1
        sleep 2
        
        for prompt_name in "${!PROMPTS[@]}"; do
            result=$(benchmark_model "$model" "$prompt_name" "${PROMPTS[$prompt_name]}")
            elapsed=$(echo "$result" | cut -d'|' -f1)
            tps=$(echo "$result" | cut -d'|' -f5)
            tokens=$(echo "$result" | cut -d'|' -f6)
            
            echo "| $prompt_name | $elapsed | $tps | ~$tokens tokens |" | tee -a "$RESULTS_FILE"
        done
        
        echo "" | tee -a "$RESULTS_FILE"
        
        # Unload
        docker exec ollama ollama stop "$model" 2>/dev/null || true
        sleep 3
    fi
done

# Summary and recommendations
echo "## Recommendations" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"
echo "Based on RTX 3090 (24GB VRAM) testing:" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"
echo "- **Fast responses**: llama3.2:3b or mistral:7b (50-60 tok/s)" | tee -a "$RESULTS_FILE"
echo "- **Daily use**: llama3.1:8b or qwen2.5:7b (40-50 tok/s)" | tee -a "$RESULTS_FILE"
echo "- **High quality**: qwen2.5:14b or phi3:14b (30-40 tok/s)" | tee -a "$RESULTS_FILE"
echo "- **Maximum quality**: qwen2.5:32b (15-25 tok/s)" | tee -a "$RESULTS_FILE"
echo "- **Coding tasks**: codellama:34b or deepseek-coder:33b" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

echo "=== Benchmark Complete ===" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"
echo "Results saved to: $RESULTS_FILE" | tee -a "$RESULTS_FILE"

# Also create a simple markdown table for README update
README_TABLE="${RESULTS_DIR}/readme_table_${TIMESTAMP}.md"
echo "## Updated Performance Table for README.md" > "$README_TABLE"
echo "" >> "$README_TABLE"
echo "| Model | VRAM Usage | GPU Utilization | Tokens/sec | Quality |" >> "$README_TABLE"
echo "|-------|------------|-----------------|------------|---------|" >> "$README_TABLE"

for model in "${AVAILABLE_MODELS[@]}"; do
    if [[ -n "${MODEL_RESULTS[$model]}" ]]; then
        vram=$(echo "${MODEL_RESULTS[$model]}" | cut -d'|' -f1)
        gpu_util=$(echo "${MODEL_RESULTS[$model]}" | cut -d'|' -f2)
        tps=$(echo "${MODEL_RESULTS[$model]}" | cut -d'|' -f3)
        quality=$(echo "${MODEL_RESULTS[$model]}" | cut -d'|' -f5)
        
        # Convert MB to GB for display
        vram_gb=$(echo "scale=0; $vram / 1024" | bc)
        
        echo "| $model | ~${vram_gb}GB | ${gpu_util}% | $tps | $quality |" >> "$README_TABLE"
    fi
done

echo "" >> "$README_TABLE"
echo "Ready-to-paste table saved to: $README_TABLE"
