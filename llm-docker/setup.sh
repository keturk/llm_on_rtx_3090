#!/bin/bash
# Setup LLM Docker Testing Environment

set -e

echo "🚀 Setting up LLM Docker Testing Environment"
echo ""

# Source the .env file to get paths
if [ -f .env ]; then
    source .env
else
    echo "❌ .env file not found!"
    exit 1
fi

# Create directory structure on NVMe drives
echo "📁 Creating directory structure..."

# Model storage directories (4TB NVMe)
sudo mkdir -p "$MODELS_PATH"/{ollama,vllm,tgi,gguf}
echo "  ✓ Model storage: $MODELS_PATH"

# Data directories (1TB NVMe)
sudo mkdir -p "$DATA_PATH"/{datasets,benchmarks,logs/{ollama,vllm,tgi},exports,open-webui}
echo "  ✓ Data storage: $DATA_PATH"

# Set permissions
echo "🔐 Setting permissions..."
sudo chown -R $USER:$USER "$MODELS_PATH" "$DATA_PATH"
echo "  ✓ Permissions set for $USER"

# Make scripts executable
echo "⚙️  Making scripts executable..."
chmod +x scripts/*.sh
echo "  ✓ Scripts are executable"

# Verify Docker is running
echo "🐳 Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi
echo "  ✓ Docker is running"

# Verify NVIDIA Docker runtime
echo "🎮 Checking NVIDIA Docker runtime..."
if docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi > /dev/null 2>&1; then
    echo "  ✓ NVIDIA Docker runtime is working"
else
    echo "❌ NVIDIA Docker runtime is not working"
    echo "   Try: sudo apt install nvidia-container-toolkit"
    echo "   Then: sudo systemctl restart docker"
    exit 1
fi

# Create symlinks in home directory for easy access
echo "🔗 Creating symlinks..."
ln -sf "$MODELS_PATH" ~/models 2>/dev/null || true
ln -sf "$DATA_PATH" ~/data 2>/dev/null || true
echo "  ✓ Symlinks created: ~/models and ~/data"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Quick start:"
echo "  1. Start Ollama:  ./scripts/start-ollama.sh"
echo "  2. Pull a model:  docker exec -it ollama ollama pull llama3.2:3b"
echo "  3. Test it:       docker exec -it ollama ollama run llama3.2:3b"
echo ""
echo "For more info, see README.md"
