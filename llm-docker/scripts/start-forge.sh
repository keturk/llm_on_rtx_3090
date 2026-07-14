#!/bin/bash
# Start Stable Diffusion WebUI Forge

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "Starting Stable Diffusion WebUI Forge..."
echo ""

# Create model directories if they don't exist
MODELS_PATH="${MODELS_PATH:-/mnt/llm-models}"
mkdir -p "$MODELS_PATH/stable-diffusion/models/Stable-diffusion"
mkdir -p "$MODELS_PATH/stable-diffusion/models/VAE"
mkdir -p "$MODELS_PATH/stable-diffusion/models/Lora"
mkdir -p "$MODELS_PATH/stable-diffusion/models/ControlNet"
mkdir -p "$MODELS_PATH/stable-diffusion/models/ESRGAN"
mkdir -p "$MODELS_PATH/stable-diffusion/outputs"
mkdir -p "$MODELS_PATH/stable-diffusion/embeddings"

echo "Model directories ready at: $MODELS_PATH/stable-diffusion/"
echo ""

# Check if Ollama is using significant VRAM
OLLAMA_VRAM=$(nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader 2>/dev/null | head -1)
if [ -n "$OLLAMA_VRAM" ]; then
    echo "Note: GPU is currently in use:"
    nvidia-smi --query-compute-apps=pid,used_memory,name --format=csv,noheader 2>/dev/null
    echo ""
    echo "Ollama will auto-unload idle models (5 min timeout)."
    echo "For best SD performance, unload large LLMs first:"
    echo "  docker exec ollama ollama stop <model>"
    echo ""
fi

# Build and start
docker compose -f docker-compose.forge.yml up -d --build

echo ""
echo "Forge is starting up..."
echo "  First run will take 5-10 minutes to install PyTorch."
echo "  Subsequent starts are fast."
echo ""
echo "Web UI:  http://localhost:${FORGE_PORT:-7860}"
echo "API:     http://localhost:${FORGE_PORT:-7860}/docs"
echo ""
echo "Logs:    docker compose -f docker-compose.forge.yml logs -f"
echo "Stop:    docker compose -f docker-compose.forge.yml down"
echo ""
echo "Model directories:"
echo "  Checkpoints: $MODELS_PATH/stable-diffusion/models/Stable-diffusion/"
echo "  LoRAs:       $MODELS_PATH/stable-diffusion/models/Lora/"
echo "  VAEs:        $MODELS_PATH/stable-diffusion/models/VAE/"
echo "  ControlNet:  $MODELS_PATH/stable-diffusion/models/ControlNet/"
echo "  Outputs:     $MODELS_PATH/stable-diffusion/outputs/"
