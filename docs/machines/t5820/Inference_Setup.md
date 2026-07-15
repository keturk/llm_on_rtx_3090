# LLM Inference Setup Guide
## Ollama Configuration, GPU Optimization, Model Testing, and Image Generation

**System:** Dell Precision T5820 with NVIDIA RTX 3090 (24GB)  
**OS:** Ubuntu 24.04.3 LTS  
**Goal:** Configure and optimize local inference with GPU acceleration — LLMs via Ollama
(port 11434) and image generation via Stable Diffusion WebUI Forge (port 7860), sharing
a single GPU

---

## Prerequisites

**Important:** This guide assumes you have completed the **[LLM System Setup Guide](System_Setup.md)** which includes:

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
5. [Stable Diffusion Server (Image Generation)](#stable-diffusion-server-image-generation)
6. [Golden Snapshot](#golden-snapshot)
7. [Quick Reference](#quick-reference)
8. [Troubleshooting](#troubleshooting)

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

## Stable Diffusion Server (Image Generation)

The same GPU that serves LLMs can also run image generation. This section adds
[Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge)
as a second inference service alongside Ollama.

### 1. Do They Conflict?

**No.** Ollama and Forge run as independent containers:

| | Ollama | Forge |
|---|--------|-------|
| Port | 11434 | 7860 |
| Container | `ollama` | `forge` |
| Compose file | `docker-compose.yml` | `docker-compose.forge.yml` |
| Network | `llm-network` | `llm-network` (shared) |

Multiple CUDA processes can hold VRAM on a single card simultaneously — the driver handles
this natively. There is no conflict at the runtime level.

The **only** constraint is total VRAM (24 GB).

### 2. VRAM Budgeting

| Workload | VRAM |
|----------|------|
| SD 1.5 | ~4 GB |
| SDXL | ~8 GB |
| FLUX.1 schnell (fp8) | ~17 GB |
| Ollama 7-8B (Q4) | ~5 GB |
| Ollama 14B (Q4) | ~9 GB |
| Ollama 32B (Q4) | ~19 GB |

- SDXL + small/medium LLM → fits comfortably.
- FLUX + large LLM → **exceeds 24 GB, will OOM.**

Ollama auto-unloads idle models after 5 minutes. To force it before a heavy image run:

```bash
docker exec ollama ollama stop <model>

# Confirm VRAM is free
nvidia-smi --query-compute-apps=pid,used_memory,name --format=csv
```

If you need both resident at once, run Forge in reduced-VRAM mode via `.env`:

```bash
FORGE_ARGS=--medvram     # slower, but frees several GB
```

### 3. Configure

Add to `.env`:

```bash
# Stable Diffusion Forge Configuration
FORGE_PORT=7860
FORGE_ARGS=
```

The service is defined in `docker-compose.forge.yml` (kept separate so Forge can be started
and stopped independently of Ollama). It uses the same `runtime: nvidia` pattern:

```yaml
services:
  forge:
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility
    ports:
      - "${FORGE_PORT:-7860}:7860"
```

### 4. Start

```bash
cd ~/llm-docker
./scripts/start-forge.sh
```

First run takes **5-10 minutes** — it builds the image and installs PyTorch (cu128) into a
persistent Docker volume (`forge-venv`), so rebuilds don't reinstall it. Later starts are fast.

```bash
# Watch the build
docker compose -f docker-compose.forge.yml logs -f

# Verify
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:7860    # expect 200
```

### 5. Add a Checkpoint

Forge is only the **server** — it ships with no weights. A *checkpoint* is the trained model
(`.safetensors`) that actually generates images. This mirrors Ollama: the server is useless
until you pull a model.

The container launches with `--no-download-sd-model`, so nothing is fetched automatically.

```bash
cd /mnt/llm-models/stable-diffusion/models/Stable-diffusion/

# SDXL base — 6.9 GB, ~8 GB VRAM, OpenRAIL++-M license
wget -O sd_xl_base_1.0.safetensors \
  "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"

# FLUX.1 schnell — 17.2 GB, ~17 GB VRAM, Apache 2.0 license
wget -O flux1-schnell-fp8.safetensors \
  "https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors"
```

Then refresh Forge's model list (no restart needed):

```bash
curl -X POST http://localhost:7860/sdapi/v1/refresh-checkpoints
curl -s http://localhost:7860/sdapi/v1/sd-models | python3 -m json.tool
```

Or click the **🔄 refresh** button next to the checkpoint dropdown in the UI.

> ⚠️ A partially-downloaded `.safetensors` will still appear in the dropdown but throws a
> corrupt-tensor error on load. Verify completeness before selecting — see the
> [Stable Diffusion Guide](Stable_Diffusion.md#adding-a-checkpoint).

### 6. Generation Settings

SDXL and FLUX need **different** settings — reusing SDXL's for FLUX produces garbage:

| | SDXL | FLUX.1 schnell |
|---|------|----------------|
| Resolution | 1024×1024 | 1024×1024 |
| Sampler | DPM++ 2M Karras | Euler + Simple |
| Steps | 25-30 | **4** (distilled) |
| CFG | 6-7 | 1.0 |

FLUX schnell is distilled to 4 steps — running *more* steps degrades output.

### 7. API Access

Forge exposes the standard A1111 API on port 7860:

```bash
curl -s -X POST http://localhost:7860/sdapi/v1/txt2img \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"a red ceramic teapot, solid white background, centered",
       "steps":25, "width":1024, "height":1024, "cfg_scale":7}' \
  | python3 -c "import json,sys,base64; open('out.png','wb').write(base64.b64decode(json.load(sys.stdin)['images'][0]))"
```

Interactive API docs: http://localhost:7860/docs

📖 Full reference, build gotchas, and troubleshooting: **[Stable Diffusion Guide](Stable_Diffusion.md)**

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

# Start Stable Diffusion (port 7860)
cd ~/llm-docker && ./scripts/start-forge.sh

# Stop Stable Diffusion
cd ~/llm-docker && docker compose -f docker-compose.forge.yml down

# Free VRAM held by an LLM (before a heavy image generation run)
docker exec ollama ollama stop <model>

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

4. **If running Ollama and Forge together** — the two share the 24 GB pool. See exactly
   what's holding VRAM, then free it:
```bash
nvidia-smi --query-compute-apps=pid,used_memory,name --format=csv

# Unload the LLM (Ollama also auto-unloads idle models after 5 min)
docker exec ollama ollama stop <model>

# Or shrink Forge's footprint — set in .env, then restart Forge:
#   FORGE_ARGS=--medvram
```

   Common overflow: FLUX (~17 GB) + a 14B+ LLM (~9 GB) exceeds 24 GB. Either use SDXL
   (~8 GB) instead, or unload the LLM first.

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
├── docker-compose.forge.yml      # Stable Diffusion Forge service
├── forge/
│   ├── Dockerfile               # Forge image (CUDA 12.8 + Python 3.12)
│   └── entrypoint.sh            # venv bootstrap + launch
└── scripts/
    ├── start-ollama.sh          # Start Ollama
    ├── start-forge.sh           # Start Stable Diffusion
    ├── stop-all.sh              # Stop all services
    └── benchmark.sh             # Performance benchmarking

/mnt/llm-models/                  # 4TB NVMe
├── ollama/                       # Ollama models
│   └── models/
│       ├── manifests/
│       └── blobs/
└── stable-diffusion/             # Image generation
    ├── models/
    │   ├── Stable-diffusion/    # Checkpoints (.safetensors)
    │   ├── VAE/
    │   ├── Lora/
    │   ├── ControlNet/
    │   └── ESRGAN/
    ├── outputs/                  # Generated images
    └── embeddings/

/mnt/llm-data/                    # 1TB NVMe
└── logs/
    └── ollama/                   # Ollama logs
```

Forge's Python venv and extensions live in Docker **named volumes** (`forge-venv`,
`forge-extensions`) rather than on the NVMe, so a container rebuild doesn't trigger a
full PyTorch reinstall.

---

## Next Steps

Your inference environment is now production ready. Consider:

1. **API Integration** - Connect applications to `http://localhost:11434` (LLM) and `http://localhost:7860` (image gen)
2. **Fine-tuning** - Create custom models with Modelfile
3. **RAG Applications** - Add vector database (ChromaDB, Qdrant)
4. **Multiple Engines** - Add vLLM or TGI for specialized workloads
5. **Image Generation** - Add LoRAs, ControlNet, and upscalers to Forge — see [Stable Diffusion Guide](Stable_Diffusion.md)
6. **Second GPU** - Enable 70B+ models, or dedicate one card to LLMs and one to image generation

---

**Document Version:** 2.0  
**Last Updated:** November 14, 2025  
**System:** Dell T5820 + RTX 3090  
**Prerequisite:** LLM_System_Setup.md  
**Status:** Production Ready ✓
