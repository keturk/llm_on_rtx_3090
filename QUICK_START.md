# Quick Start

Get up and running with local LLMs in under 5 minutes.

> **Which machine?** This repo supports two. Run `./setup.sh` from the repo root — it detects
> your machine and points you the right way. Full comparison: [docs/MACHINES.md](docs/MACHINES.md).
>
> - **ASUS GX10 (ARM, native Ollama)** → jump to [GX10 Quick Start](#gx10-quick-start-arm--native) below.
> - **Dell T5820 (x86, RTX 3090, Docker)** → continue with the sections below.

---

## GX10 Quick Start (ARM / native)

On the GX10, Ollama already runs as a native systemd service — no Docker, no `docker exec`.

```bash
cd ~/llm_on_rtx_3090
./setup.sh                                    # verify the environment

ollama list                                   # installed models (stored in /opt/models)
ollama run nemotron-3-nano:30b "Hello!"       # 30B model
ollama run nemotron-3-super:120b "Explain unified memory"   # 120B — fits in unified RAM!
ollama pull qwen3:14b                          # download another model
```

The server listens on **port 11500** (`http://127.0.0.1:11500`); the default `ollama` CLI works
without any host flag. Full details: [GX10 Setup guide](docs/machines/gx10/Setup.md).

The rest of this document is the **Dell T5820 / RTX 3090 (Docker)** path.

---

## Prerequisites Check

```bash
# Verify GPU is detected
nvidia-smi

# Verify Docker has GPU access
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

If either command fails, see [docs/machines/t5820/System_Setup.md](docs/machines/t5820/System_Setup.md) for full setup.

---

## 1. Initial Setup (One Time)

```bash
cd llm-docker
./setup.sh
```

This creates directories, verifies Docker, and makes scripts executable.

---

## 2. Start Ollama

```bash
./scripts/start-ollama.sh
```

Starts the Ollama Docker container and verifies connectivity.

---

## 3. Download Your First Model

```bash
# FASTEST (7.8B, ~5GB VRAM, 90.1 tok/s) 🆕
docker exec -it ollama ollama pull exaone-deep:7.8b

# Fast baseline (3B, ~3GB VRAM, 52.3 tok/s)
docker exec -it ollama ollama pull llama3.2:3b

# Next-gen balanced (8B, ~5GB VRAM, 62.1 tok/s) 🆕
docker exec -it ollama ollama pull qwen3:8b

# High quality (14B, ~9GB VRAM, 43.2 tok/s) 🆕
docker exec -it ollama ollama pull qwen3:14b

# Best reasoning (14B, ~9GB VRAM, 56.6 tok/s) 🆕
docker exec -it ollama ollama pull deepseek-r1:14b
```

---

## 4. Test It

```bash
# Interactive chat
docker exec -it ollama ollama run llama3.2:3b

# Single query
docker exec -it ollama ollama run llama3.2:3b "Explain quantum computing in one sentence"

# API test
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Hello!"
}'
```

---

## 5. Run Benchmarks (Optional)

```bash
# Quick benchmark (single model)
./scripts/benchmark.sh ollama 10

# Full automated benchmark (48 models)
./scripts/run-full-benchmark.sh
```

---

## 6. Image Generation (Optional)

Stable Diffusion runs on the **same GPU** as Ollama — no conflict, they just share the
24 GB VRAM pool.

```bash
# Start Forge (5-10 min on first run — installs PyTorch)
./scripts/start-forge.sh

# Open the UI
#   http://localhost:7860
```

Forge has **no model weights** out of the box. Download a checkpoint:

```bash
cd /mnt/llm-models/stable-diffusion/models/Stable-diffusion/

# SDXL — 6.9 GB, ~8 GB VRAM, good all-rounder
wget -O sd_xl_base_1.0.safetensors \
  "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
```

Then hit the **🔄 refresh** button next to the checkpoint dropdown in the UI.

> ⚠️ Running FLUX (~17 GB) plus a large LLM will exceed 24 GB. Free the LLM first:
> `docker exec ollama ollama stop <model>`

📖 [Full Stable Diffusion Guide](docs/machines/t5820/Stable_Diffusion.md)

---

## Common Commands

```bash
# List installed models
docker exec -it ollama ollama list

# Remove a model
docker exec -it ollama ollama rm llama3.2:3b

# Stop all services
./scripts/stop-all.sh
docker compose -f docker-compose.forge.yml down   # stop Forge

# Free VRAM held by an LLM (before heavy image generation)
docker exec ollama ollama stop <model>

# Monitor GPU
watch -n 1 nvidia-smi
```

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| Ollama | 11434 | http://localhost:11434 |
| Forge (Stable Diffusion) | 7860 | http://localhost:7860 |

---

## Next Steps

1. **Try More Models:** See [docs/shared/Models_and_Benchmarks.md](docs/shared/Models_and_Benchmarks.md) for recommendations
2. **Run Benchmarks:** Use `./scripts/run-full-benchmark.sh` to test performance
3. **Read Full Guide:** Check [llm-docker/README.md](llm-docker/README.md) for detailed usage

---

## Quick Model Recommendations (January 2026)

| Use Case | Model Command | VRAM | Speed |
|----------|--------------|------|-------|
| **🏆 Fastest** | `ollama pull exaone-deep:7.8b` 🆕 | ~5GB | 90.1 tok/s |
| **Testing** | `ollama pull llama3.2:3b` | ~3GB | 52.3 tok/s |
| **Daily Use** | `ollama pull qwen3:8b` 🆕 | ~5GB | 62.1 tok/s |
| **Reasoning** | `ollama pull deepseek-r1:14b` 🆕 | ~9GB | 56.6 tok/s |
| **Coding** | `ollama pull qwen2.5-coder:14b` | ~9GB | 29.2 tok/s |
| **Vision** | `ollama pull qwen3-vl:8b` 🆕 | ~7GB | 40.9 tok/s |
| **Quality** | `ollama pull qwen3:14b` 🆕 | ~9GB | 43.2 tok/s |
| **Max Quality** | `ollama pull qwen2.5:32b` | ~19GB | 21.4 tok/s |

---

## Troubleshooting

**Ollama won't start:**
```bash
docker compose logs ollama
./scripts/stop-all.sh && ./scripts/start-ollama.sh
```

**Out of memory:**
```bash
nvidia-smi  # Check VRAM usage
docker exec ollama ollama stop <model-name>  # Unload model
```

**Slow performance:**
```bash
nvidia-smi  # Check GPU utilization
# Try a smaller model or Q4 quantization
```

---

**Need help?** See [llm-docker/CHEATSHEET.txt](llm-docker/CHEATSHEET.txt) for command reference or [llm-docker/README.md](llm-docker/README.md) for full documentation.
