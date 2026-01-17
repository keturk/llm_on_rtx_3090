#!/bin/bash
# Benchmark LLM inference performance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

SERVICE="$1"
ITERATIONS="${2:-10}"
OUTPUT_DIR="${DATA_PATH}/benchmarks"

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <service> [iterations]"
    echo ""
    echo "Services: ollama, vllm, tgi"
    echo "Example: $0 ollama 20"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="$OUTPUT_DIR/${SERVICE}_${TIMESTAMP}.txt"

echo "🔬 Benchmarking $SERVICE with $ITERATIONS iterations"
echo "Results will be saved to: $RESULT_FILE"
echo ""

# Test prompts
PROMPTS=(
    "What is the capital of France?"
    "Explain quantum computing in simple terms."
    "Write a haiku about programming."
    "What are the benefits of exercise?"
    "Translate 'Hello, world!' to Spanish."
)

{
    echo "==================================="
    echo "LLM Benchmark Results"
    echo "==================================="
    echo "Service: $SERVICE"
    echo "Date: $(date)"
    echo "Iterations: $ITERATIONS"
    echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader)"
    echo "==================================="
    echo ""
} > "$RESULT_FILE"

for i in $(seq 1 $ITERATIONS); do
    PROMPT="${PROMPTS[$((i % ${#PROMPTS[@]}))]}"
    
    echo -n "Iteration $i/$ITERATIONS... "
    
    START=$(date +%s.%N)
    
    case "$SERVICE" in
        ollama)
            OLLAMA_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i ollama | head -1)
            MODEL=$(docker exec "$OLLAMA_CONTAINER" ollama list | tail -n +2 | head -n 1 | awk '{print $1}')
            RESPONSE=$(docker exec "$OLLAMA_CONTAINER" ollama run "$MODEL" "$PROMPT" 2>&1)
            ;;
        vllm)
            RESPONSE=$(curl -s http://localhost:8000/v1/completions \
                -H "Content-Type: application/json" \
                -d "{\"model\": \"meta-llama/Llama-3.2-3B-Instruct\", \"prompt\": \"$PROMPT\", \"max_tokens\": 100}" \
                | jq -r '.choices[0].text')
            ;;
        tgi)
            RESPONSE=$(curl -s http://localhost:8080/generate \
                -H "Content-Type: application/json" \
                -d "{\"inputs\": \"$PROMPT\", \"parameters\": {\"max_new_tokens\": 100}}" \
                | jq -r '.generated_text')
            ;;
    esac
    
    END=$(date +%s.%N)
    DURATION=$(echo "$END - $START" | bc)
    
    echo "${DURATION}s"
    
    {
        echo "--- Iteration $i ---"
        echo "Prompt: $PROMPT"
        echo "Duration: ${DURATION}s"
        echo "Response: $RESPONSE"
        echo ""
    } >> "$RESULT_FILE"
done

# Calculate statistics
echo ""
echo "📊 Calculating statistics..."

AVG_TIME=$(awk '/Duration:/ {sum+=$2; count++} END {print sum/count}' "$RESULT_FILE")

{
    echo "==================================="
    echo "Summary Statistics"
    echo "==================================="
    echo "Average response time: ${AVG_TIME}s"
    echo ""
} >> "$RESULT_FILE"

echo "✅ Benchmark complete!"
echo "Results saved to: $RESULT_FILE"
echo "Average response time: ${AVG_TIME}s"
