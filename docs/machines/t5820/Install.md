# Installation Guide

## Prerequisites

✅ Ubuntu 24.04.3 LTS installed  
✅ NVIDIA driver 570 installed  
✅ Docker installed  
✅ NVIDIA Container Toolkit installed  

## Step 1: Mount NVMe Drives (If Not Already Mounted)

```bash
# Check current mounts
lsblk

# If nvme drives aren't mounted to /mnt/llm-* yet:
sudo mkdir -p /mnt/llm-models /mnt/llm-data

# Get UUIDs
sudo blkid /dev/nvme0n1p1 /dev/nvme1n1p1

# Add to /etc/fstab (replace UUIDs with your actual UUIDs)
echo "UUID=your-1tb-uuid /mnt/llm-data ext4 defaults 0 2" | sudo tee -a /etc/fstab
echo "UUID=your-4tb-uuid /mnt/llm-models ext4 defaults 0 2" | sudo tee -a /etc/fstab

# Mount all
sudo mount -a

# Verify
df -h | grep llm
```

## Step 2: Copy Files to Your System

```bash
# From wherever you extracted this package:
cp -r llm-docker ~/llm-docker
cd ~/llm-docker
```

## Step 3: Update .env File

Edit `.env` and verify paths:

```bash
nano .env

# Make sure these match your setup:
MODELS_PATH=/mnt/llm-models
DATA_PATH=/mnt/llm-data
```

## Step 4: Run Setup

```bash
./setup.sh
```

This will:
- Create all necessary directories
- Set correct permissions
- Verify Docker and NVIDIA runtime
- Create helpful symlinks

## Step 5: Test Installation

```bash
# Start Ollama
./scripts/start-ollama.sh

# Pull a small model
docker exec -it ollama ollama pull llama3.2:3b

# Test it
docker exec -it ollama ollama run llama3.2:3b "Hello! Tell me a joke."

# If that works, you're all set! 🎉
```

## Step 6: Pull More Models (Optional)

```bash
# Pull a set of small models for testing
./scripts/batch-pull-models.sh small

# Or pull medium-sized models
./scripts/batch-pull-models.sh medium

# List what you have
docker exec ollama ollama list
```

## Step 7: Install the Stable Diffusion Server (Optional)

Image generation via [Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge),
running alongside Ollama on the same GPU.

```bash
cd ~/llm-docker
./scripts/start-forge.sh
```

First run takes **5-10 minutes** (builds the image, installs PyTorch into a persistent
volume). Later starts are fast. When it's up:

| Service | URL |
|---------|-----|
| Forge Web UI | http://localhost:7860 |
| Ollama API | http://localhost:11434 |

### Add a Checkpoint

Forge ships with **no model weights** — it's just the server. You need a *checkpoint*
(a `.safetensors` file) before it can generate anything, exactly like `ollama pull` for LLMs.

```bash
cd /mnt/llm-models/stable-diffusion/models/Stable-diffusion/

# SDXL base (6.9 GB, ~8 GB VRAM) — broad style range, huge LoRA ecosystem
wget -O sd_xl_base_1.0.safetensors \
  "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"

# FLUX.1 schnell (17.2 GB, ~17 GB VRAM) — Apache 2.0, best prompt-following
wget -O flux1-schnell-fp8.safetensors \
  "https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors"
```

Then click the **🔄 refresh** button next to the checkpoint dropdown in the UI — no restart
needed.

### Ollama and Forge Share the GPU

They do **not** conflict — separate ports, separate containers, and multiple CUDA processes
can hold VRAM on one card simultaneously. The only limit is **total VRAM (24 GB)**:

- SDXL (~8 GB) + a small/medium LLM → comfortable.
- FLUX (~17 GB) + a large LLM → **will OOM**. Free the LLM first:

```bash
docker exec ollama ollama stop <model>
```

Ollama also auto-unloads idle models after 5 minutes, so conflicts often clear on their own.

📖 Full details: [Stable Diffusion Guide](Stable_Diffusion.md)

## Troubleshooting

### Docker Permission Denied
```bash
sudo usermod -aG docker $USER
newgrp docker
# Log out and back in
```

### NVIDIA Runtime Not Found
```bash
sudo apt install nvidia-container-toolkit
sudo systemctl restart docker
```

### Disk Space Issues
```bash
# Check space
df -h /mnt/llm-models
df -h /mnt/llm-data

# Clean Docker cache
docker system prune -a
```

### Port Already in Use
```bash
# Check what's using port 11434 (Ollama) or 7860 (Forge)
sudo lsof -i :11434
sudo lsof -i :7860

# Stop conflicting service, or change OLLAMA_PORT / FORGE_PORT in .env
```

### Out of GPU Memory (Ollama + Forge together)
```bash
# See what's holding VRAM
nvidia-smi --query-compute-apps=pid,used_memory,name --format=csv

# Free the LLM before a heavy image generation run
docker exec ollama ollama stop <model>

# Or run Forge in low-VRAM mode — set in .env:
#   FORGE_ARGS=--medvram
```

## Next Steps

Once installed:

1. **Read the README.md** for usage examples
2. **Check Model_Guide.md** for model recommendations
3. **Start testing**: Try different models and quantizations
4. **Benchmark**: Use `./scripts/benchmark.sh` to compare performance

## Quick Reference

```bash
# Start services
./scripts/start-ollama.sh
./scripts/start-forge.sh              # Stable Diffusion (port 7860)
./scripts/start-vllm.sh [model]
./scripts/start-tgi.sh [model]

# Stop all services
./scripts/stop-all.sh
docker compose -f docker-compose.forge.yml down    # stop Forge

# Test a model
./scripts/test-model.sh ollama "What is AI?"

# Run benchmark
./scripts/benchmark.sh ollama 10

# Monitor GPU
watch -n 1 nvidia-smi
```

## File Locations

- **Docker configs**: `~/llm-docker/`
- **Model storage**: `/mnt/llm-models/` (symlink: `~/models`)
- **LLM models**: `/mnt/llm-models/ollama/`
- **SD checkpoints**: `/mnt/llm-models/stable-diffusion/models/Stable-diffusion/`
- **SD outputs**: `/mnt/llm-models/stable-diffusion/outputs/`
- **Working data**: `/mnt/llm-data/` (symlink: `~/data`)
- **Benchmarks**: `/mnt/llm-data/benchmarks/`
- **Logs**: `/mnt/llm-data/logs/`
