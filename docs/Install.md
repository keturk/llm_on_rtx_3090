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
# Check what's using port 11434
sudo lsof -i :11434

# Stop conflicting service or change port in .env
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
./scripts/start-vllm.sh [model]
./scripts/start-tgi.sh [model]

# Stop all services
./scripts/stop-all.sh

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
- **Working data**: `/mnt/llm-data/` (symlink: `~/data`)
- **Benchmarks**: `/mnt/llm-data/benchmarks/`
- **Logs**: `/mnt/llm-data/logs/`
