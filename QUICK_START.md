# LLM on RTX 3090 - Quick Start

Get up and running with LLMs on your RTX 3090 in under 5 minutes.

---

## Prerequisites Check

```bash
# Verify GPU is detected
nvidia-smi

# Verify Docker has GPU access
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

If either command fails, see [docs/LLM_System_Setup.md](docs/LLM_System_Setup.md) for full setup.

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
# Fast baseline (3B, ~2GB VRAM)
docker exec -it ollama ollama pull llama3.2:3b

# Balanced quality (8B, ~5GB VRAM)
docker exec -it ollama ollama pull llama3.1:8b

# High quality (14B, ~9GB VRAM)
docker exec -it ollama ollama pull qwen2.5:14b
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

# Full automated benchmark (34 models)
./scripts/run-full-benchmark.sh
```

---

## Common Commands

```bash
# List installed models
docker exec -it ollama ollama list

# Remove a model
docker exec -it ollama ollama rm llama3.2:3b

# Stop all services
./scripts/stop-all.sh

# Monitor GPU
watch -n 1 nvidia-smi
```

---

## Next Steps

1. **Try More Models:** See [docs/Models_and_Benchmarks.md](docs/Models_and_Benchmarks.md) for recommendations
2. **Run Benchmarks:** Use `./scripts/run-full-benchmark.sh` to test performance
3. **Read Full Guide:** Check [llm-docker/README.md](llm-docker/README.md) for detailed usage

---

## Quick Model Recommendations

| Use Case | Model Command | VRAM | Speed |
|----------|--------------|------|-------|
| **Testing** | `ollama pull llama3.2:3b` | ~2GB | 50-60 tok/s |
| **Daily Use** | `ollama pull llama3.1:8b` | ~5GB | 40-50 tok/s |
| **Coding** | `ollama pull qwen2.5-coder:14b` | ~9GB | 30-40 tok/s |
| **Quality** | `ollama pull qwen2.5:32b` | ~21GB | 15-25 tok/s |

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
