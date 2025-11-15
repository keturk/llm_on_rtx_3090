# LLM Inference Setup Guide
## Ollama Configuration, GPU Optimization, and Model Testing

**System:** Dell Precision T5820 with NVIDIA RTX 3090 (24GB)  
**OS:** Ubuntu 24.04.3 LTS  
**Goal:** Configure and optimize local LLM inference with GPU acceleration

---

## Prerequisites

**Important:** This guide assumes you have completed the **[LLM System Setup Guide](LLM_System_Setup.md)** which includes:

- ✓ Ubuntu 24.04.3 LTS installation
- ✓ NVIDIA 570-open driver (570.195.03)
- ✓ Docker Engine 29.0.1 with Compose v2.40.3
- ✓ NVIDIA Container Toolkit configured
- ✓ NVMe drives mounted at `/mnt/llm-data` (1TB) and `/mnt/llm-models` (4TB)
- ✓ LLM directory structure created
- ✓ Initial system Timeshift snapshot

**Quick Verification:**
```bash
~/check-system.sh
```

If any components are missing, complete the LLM System Setup Guide first.

---

## Table of Contents
1. [Ollama Docker Configuration](#ollama-docker-configuration)
2. [GPU Optimization](#gpu-optimization)
3. [Model Testing & Validation](#model-testing-validation)
4. [Performance Benchmarking](#performance-benchmarking)
5. [Golden Snapshot](#golden-snapshot)
6. [Quick Reference](#quick-reference)
7. [Troubleshooting](#troubleshooting)

---

## Ollama Docker Configuration

### 1. Create Project Directory

```bash
mkdir -p ~/llm-docker
cd ~/llm-docker
```

### 2. Create Environment Configuration

```bash
cat > .env << 'EOF'
# LLM Docker Environment Configuration

# Storage Paths
MODELS_PATH=/mnt/llm-models
DATA_PATH=/mnt/llm-data

# Ollama Configuration
OLLAMA_MODELS=${MODELS_PATH}/ollama
OLLAMA_PORT=11434

# GPU Configuration
CUDA_VISIBLE_DEVICES=0
GPU_MEMORY_UTILIZATION=0.90

# Logging
LOG_LEVEL=INFO
LOG_PATH=${DATA_PATH}/logs
EOF
```

### 3. Create Docker Compose File

```bash
cat > docker-compose.yml << 'EOF'
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    runtime: nvidia
    ports:
      - "${OLLAMA_PORT:-11434}:11434"
    volumes:
      - ${OLLAMA_MODELS:-/mnt/llm-models/ollama}:/root/.ollama
      - ${LOG_PATH:-/mnt/llm-data/logs}/ollama:/var/log/ollama
    environment:
      - OLLAMA_DEBUG=1
      - CUDA_VISIBLE_DEVICES=0
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility

networks:
  default:
    name: llm-network
EOF
```

**Key Configuration Points:**
- `runtime: nvidia` - Ensures GPU access (more reliable than `deploy:` syntax)
- `NVIDIA_VISIBLE_DEVICES=all` - Makes all GPUs visible to container
- `NVIDIA_DRIVER_CAPABILITIES=compute,utility` - Required capabilities for inference
- Models stored on 4TB NVMe at `/mnt/llm-models/ollama`
- Logs stored on 1TB NVMe at `/mnt/llm-data/logs/ollama`

### 4. Create Management Scripts

**Start Script:**
```bash
mkdir -p scripts

cat > scripts/start-ollama.sh << 'EOF'
#!/bin/bash
# Start Ollama service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "🚀 Starting Ollama..."
docker compose up -d

echo "⏳ Waiting for Ollama to be ready..."
sleep 5

# Check if Ollama is responding
MAX_TRIES=10
for i in $(seq 1 $MAX_TRIES); do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama is running!"
        echo ""
        echo "Available commands:"
        echo "  docker exec -it ollama ollama list"
        echo "  docker exec -it ollama ollama pull llama3.2:3b"
        echo "  docker exec -it ollama ollama run llama3.2:3b"
        echo ""
        echo "API endpoint: http://localhost:11434"
        exit 0
    fi
    echo "Waiting... ($i/$MAX_TRIES)"
    sleep 2
done

echo "❌ Ollama failed to start properly"
docker logs ollama 2>&1 | tail -20
exit 1
EOF

chmod +x scripts/start-ollama.sh
```

**Stop Script:**
```bash
cat > scripts/stop-all.sh << 'EOF'
#!/bin/bash
# Stop all LLM services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "🛑 Stopping all LLM services..."

docker compose down 2>/dev/null || true

echo "✅ All services stopped"
echo ""
docker ps --filter "name=ollama"
EOF

chmod +x scripts/stop-all.sh
```

### 5. Start and Verify

```bash
# Start Ollama
./scripts/start-ollama.sh

# Verify GPU access inside container
docker exec ollama nvidia-smi
```

Expected output should show the RTX 3090 with full 24GB VRAM available.

---

## GPU Optimization

### Verify GPU Inference

After starting Ollama, confirm models run on GPU:

```bash
# Pull and run a small model
docker exec -it ollama ollama pull llama3.2:3b
docker exec -it ollama ollama run llama3.2:3b "Hello" > /dev/null 2>&1 &
sleep 3

# Check GPU usage
nvidia-smi
```

Look for:
- Memory usage increased (model loaded into VRAM)
- GPU utilization when generating tokens

### Check Inference Backend

```bash
docker logs ollama 2>&1 | grep "inference compute"
```

Expected output:
```
id=GPU-xxx library=CUDA name=CUDA0 description="NVIDIA GeForce RTX 3090" 
total="24.0 GiB" available="23.0 GiB"
```

**Red Flag:** If you see `dev = CPU` in the logs:
```bash
docker logs ollama | grep "dev ="
# Bad: llama_kv_cache: layer XX: dev = CPU
```

This means models are running on CPU. See [Troubleshooting](#models-running-on-cpu-instead-of-gpu) section.

### Monitor GPU During Inference

```bash
# Terminal 1: Run a query
docker exec -it ollama ollama run qwen2.5:32b "Explain quantum computing in detail"

# Terminal 2: Watch GPU metrics
watch -n 0.5 nvidia-smi
```

For the 32B model, expect:
- Memory: ~21GB / 24GB
- GPU Utilization: 80-97%
- Power: 200-300W
- Temperature: 50-65°C

---

## Model Testing & Validation

### Recommended Models for RTX 3090 (24GB VRAM)

**Models That Fit Entirely on GPU:**

| Model | VRAM | Use Case | Quality |
|-------|------|----------|---------|
| llama3.2:3b | ~2GB | Testing, chatbots | Good |
| llama3.1:8b | ~5GB | Daily use, coding | Very Good |
| qwen2.5:7b | ~5GB | General purpose | Very Good |
| qwen2.5:14b | ~9GB | Production use | Excellent |
| phi3:14b | ~8GB | Balanced performance | Excellent |
| **qwen2.5:32b** | ~19GB | **Maximum quality** | **Best** |

**Models to AVOID (too large for single RTX 3090):**
- llama3.1:70b - 26GB+ (won't fit)
- qwen2.5:72b - 36GB+ (won't fit)

### Download Recommended Models

```bash
# Essential models
docker exec -it ollama ollama pull llama3.2:3b
docker exec -it ollama ollama pull llama3.1:8b

# Production models
docker exec -it ollama ollama pull qwen2.5:14b

# Maximum quality (uses 21GB VRAM)
docker exec -it ollama ollama pull qwen2.5:32b
```

### Test Model Quality

**Basic Test:**
```bash
docker exec -it ollama ollama run llama3.2:3b "What is 2+2?"
```

**Reasoning Test:**
```bash
# Compare 3B vs 32B on complex reasoning
echo "=== 3B Model ==="
docker exec -it ollama ollama run llama3.2:3b "Explain the difference between supervised and unsupervised learning"

echo "=== 32B Model ==="
docker exec -it ollama ollama run qwen2.5:32b "Explain the difference between supervised and unsupervised learning"
```

### Verify Storage Usage

```bash
# Check model storage
du -sh /mnt/llm-models/ollama
docker exec -it ollama ollama list
```

Expected output (with all recommended models):
```
NAME            SIZE
llama3.2:3b     2.0 GB
llama3.1:8b     4.7 GB
qwen2.5:14b     8.9 GB
qwen2.5:32b     19 GB
```

---

## Performance Benchmarking

### Speed Test Script

```bash
cat > scripts/benchmark.sh << 'EOF'
#!/bin/bash
# Benchmark LLM inference speed

echo "=== LLM Performance Benchmark ==="
echo "Task: Count from 1 to 20"
echo ""

for model in llama3.2:3b llama3.1:8b qwen2.5:14b qwen2.5:32b; do
    echo "Testing $model..."
    
    # Check if model exists
    if ! docker exec ollama ollama list 2>/dev/null | grep -q "$model"; then
        echo "  ⚠️  Model not installed, skipping"
        continue
    fi
    
    # Time the inference
    START=$(date +%s.%N)
    docker exec ollama ollama run "$model" "Count from 1 to 20" > /dev/null 2>&1
    END=$(date +%s.%N)
    
    ELAPSED=$(echo "$END - $START" | bc)
    echo "  ✓ Time: ${ELAPSED}s"
    echo ""
done

echo "=== Benchmark Complete ==="
EOF

chmod +x scripts/benchmark.sh
```

Run benchmark:
```bash
./scripts/benchmark.sh
```

### Expected Results

| Model | Count 1-20 Time | Tokens/sec (approx) |
|-------|----------------|---------------------|
| llama3.2:3b | 2.8s | ~50-60 |
| llama3.1:8b | 3.0s | ~40-50 |
| qwen2.5:14b | 4.5s | ~30-40 |
| qwen2.5:32b | 9.9s | ~15-25 |

### GPU Utilization Test

```bash
# Run intensive query and monitor
docker exec -it ollama ollama run qwen2.5:32b "Write a 500-word essay on artificial intelligence" &
watch -n 0.5 nvidia-smi
```

Look for sustained GPU utilization above 80%.

---

## Golden Snapshot

After successful configuration and testing, create a restore point.

### 1. Stop All Services

```bash
cd ~/llm-docker
./scripts/stop-all.sh
```

### 2. Verify System State

```bash
# Check what's installed
docker exec -it ollama ollama list 2>/dev/null || echo "Ollama stopped (correct)"

# Check disk usage
df -h /mnt/llm-models
df -h /mnt/llm-data

# Verify Docker images
docker images | grep ollama
```

### 3. Create Golden Snapshot

```bash
sudo timeshift --create --comments "Golden: LLM Ready - GPU Working - Ollama + Models (3B/8B/14B/32B)"
```

### 4. Verify Snapshot

```bash
sudo timeshift --list
```

### 5. Test Restore (Optional but Recommended)

```bash
# To restore to golden snapshot (if needed)
sudo timeshift --restore

# After reboot, verify everything works
cd ~/llm-docker
./scripts/start-ollama.sh
docker exec -it ollama ollama run llama3.2:3b "test"
```

---

## Quick Reference

### Daily Operations

```bash
# Start Ollama
cd ~/llm-docker && ./scripts/start-ollama.sh

# Stop Ollama
cd ~/llm-docker && ./scripts/stop-all.sh

# List installed models
docker exec -it ollama ollama list

# Run a model interactively
docker exec -it ollama ollama run llama3.2:3b

# Run with specific prompt
docker exec -it ollama ollama run qwen2.5:14b "Your prompt here"

# Pull new model
docker exec -it ollama ollama pull mistral:7b

# Remove model
docker exec -it ollama ollama rm model-name

# Check GPU usage
nvidia-smi

# Check model storage
df -h /mnt/llm-models
```

### Monitoring

```bash
# Real-time GPU monitoring
watch -n 1 nvidia-smi

# Ollama logs
docker logs -f ollama

# Container resource usage
docker stats ollama

# Check if using GPU
docker logs ollama 2>&1 | grep "inference compute"
```

### API Access

Ollama exposes a REST API at `http://localhost:11434`:

```bash
# List models via API
curl http://localhost:11434/api/tags

# Generate completion
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Why is the sky blue?"
}'

# Chat completion
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [
    { "role": "user", "content": "Hello!" }
  ]
}'
```

---

## Troubleshooting

### Models Running on CPU Instead of GPU

**Symptoms:**
```bash
docker logs ollama | grep "dev ="
# Shows: llama_kv_cache: layer XX: dev = CPU
```

**Solution:**

1. Verify NVIDIA runtime is configured:
```bash
docker info | grep -i runtime
# Should list "nvidia"
```

2. Check docker-compose.yml uses `runtime: nvidia` (not `deploy:` syntax)

3. Restart Docker and Ollama:
```bash
sudo systemctl restart docker
cd ~/llm-docker
./scripts/stop-all.sh
./scripts/start-ollama.sh
```

4. Verify GPU access:
```bash
docker exec ollama nvidia-smi
```

### Slow Model Performance

**Symptoms:**
- 1-5 tokens/second
- GPU utilization below 20%

**Causes and Solutions:**

1. **Model too large** - Offloading to CPU
   - Check: `nvidia-smi` shows memory at or over 24GB
   - Solution: Use smaller model (qwen2.5:32b maximum for RTX 3090)

2. **Thermal throttling**
   - Check: GPU temp >85°C in nvidia-smi
   - Solution: Improve case airflow, check GPU fans

3. **Wrong runtime**
   - Check: `docker logs ollama | grep "dev = CPU"`
   - Solution: Fix docker-compose.yml runtime configuration

### Cannot Access Ollama API

**Symptoms:**
```bash
curl http://localhost:11434/api/tags
# Connection refused
```

**Solutions:**

1. Check if container is running:
```bash
docker ps | grep ollama
```

2. Check port binding:
```bash
docker port ollama
netstat -tulpn | grep 11434
```

3. Restart Ollama:
```bash
./scripts/stop-all.sh
./scripts/start-ollama.sh
```

4. Check logs:
```bash
docker logs ollama | tail -50
```

### Model Download Fails

**Symptoms:** Download hangs or fails partway through

**Solutions:**

1. Check disk space:
```bash
df -h /mnt/llm-models
```

2. Check network:
```bash
ping ollama.com
```

3. Retry download:
```bash
docker exec -it ollama ollama pull model-name
```

4. Clear partial downloads and retry:
```bash
docker exec -it ollama ollama rm model-name
docker exec -it ollama ollama pull model-name
```

### Out of GPU Memory

**Symptoms:**
```
CUDA out of memory
```

**Solutions:**

1. Use smaller model
2. Reduce context length:
```bash
docker exec -it ollama ollama run model-name --ctx-size 2048
```

3. Check for other GPU processes:
```bash
nvidia-smi
```

---

## Performance Optimization Tips

### 1. Model Selection Strategy

- **Quick responses:** llama3.2:3b (fast, good quality)
- **Daily work:** llama3.1:8b or qwen2.5:7b (balanced)
- **Complex tasks:** qwen2.5:14b (excellent quality)
- **Maximum quality:** qwen2.5:32b (best reasoning, slower)

### 2. Context Length Tuning

Shorter context = faster inference:
```bash
# Fast mode (2K context)
docker exec -it ollama ollama run model --ctx-size 2048

# Standard (4K context - default)
docker exec -it ollama ollama run model

# Extended (8K context - slower)
docker exec -it ollama ollama run model --ctx-size 8192
```

### 3. Temperature Settings

```bash
# Deterministic (fast, consistent)
docker exec -it ollama ollama run model --temperature 0.1

# Balanced (default)
docker exec -it ollama ollama run model --temperature 0.7

# Creative (slower, more varied)
docker exec -it ollama ollama run model --temperature 0.9
```

---

## File Structure Summary

```
~/llm-docker/
├── .env                          # Environment configuration
├── docker-compose.yml            # Ollama service definition
└── scripts/
    ├── start-ollama.sh          # Start Ollama
    ├── stop-all.sh              # Stop all services
    └── benchmark.sh             # Performance benchmarking

/mnt/llm-models/                  # 4TB NVMe
└── ollama/                       # Ollama models
    └── models/
        ├── manifests/
        └── blobs/

/mnt/llm-data/                    # 1TB NVMe
└── logs/
    └── ollama/                   # Ollama logs
```

---

## Next Steps

Your LLM inference environment is now production ready. Consider:

1. **API Integration** - Connect applications to `http://localhost:11434`
2. **Fine-tuning** - Create custom models with Modelfile
3. **RAG Applications** - Add vector database (ChromaDB, Qdrant)
4. **Multiple Engines** - Add vLLM or TGI for specialized workloads
5. **Second GPU** - Enable 70B+ models with additional RTX 3090

---

**Document Version:** 2.0  
**Last Updated:** November 14, 2025  
**System:** Dell T5820 + RTX 3090  
**Prerequisite:** LLM_System_Setup.md  
**Status:** Production Ready ✓
