#!/bin/bash
# Test LLM inference with a simple prompt

set -e

SERVICE="$1"
PROMPT="${2:-Hello, how are you?}"

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <service> [prompt]"
    echo ""
    echo "Services: ollama, vllm, tgi"
    echo "Example: $0 ollama 'What is the capital of France?'"
    exit 1
fi

case "$SERVICE" in
    ollama)
        echo "🧪 Testing Ollama..."
        echo "Prompt: $PROMPT"
        echo ""

        # Find Ollama container dynamically
        OLLAMA_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i ollama | head -1)
        if [ -z "$OLLAMA_CONTAINER" ]; then
            echo "❌ Could not find Ollama container. Make sure it's running."
            exit 1
        fi

        # Get first available model
        MODEL=$(docker exec "$OLLAMA_CONTAINER" ollama list | tail -n +2 | head -n 1 | awk '{print $1}')

        if [ -z "$MODEL" ]; then
            echo "❌ No models found. Pull a model first:"
            echo "  docker exec -it $OLLAMA_CONTAINER ollama pull llama3.2:3b"
            exit 1
        fi

        echo "Using model: $MODEL"
        echo "---"
        docker exec "$OLLAMA_CONTAINER" ollama run "$MODEL" "$PROMPT"
        ;;
        
    vllm)
        echo "🧪 Testing vLLM..."
        echo "Prompt: $PROMPT"
        echo ""
        
        curl -s http://localhost:8000/v1/completions \
            -H "Content-Type: application/json" \
            -d "{
                \"model\": \"meta-llama/Llama-3.2-3B-Instruct\",
                \"prompt\": \"$PROMPT\",
                \"max_tokens\": 100,
                \"temperature\": 0.7
            }" | jq -r '.choices[0].text'
        ;;
        
    tgi)
        echo "🧪 Testing TGI..."
        echo "Prompt: $PROMPT"
        echo ""
        
        curl -s http://localhost:8080/generate \
            -H "Content-Type: application/json" \
            -d "{
                \"inputs\": \"$PROMPT\",
                \"parameters\": {
                    \"max_new_tokens\": 100,
                    \"temperature\": 0.7
                }
            }" | jq -r '.generated_text'
        ;;
        
    *)
        echo "❌ Unknown service: $SERVICE"
        echo "Available services: ollama, vllm, tgi"
        exit 1
        ;;
esac
