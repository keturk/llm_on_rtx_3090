# LLM Docker - Quick Reference

Quick reference for LLM inference engines on Dell T5820 with RTX 3090.

> **New User?** Start with [../QUICK_START.md](../QUICK_START.md) for 5-minute setup guide.

---

## Table of Contents
- [Quick Start](#quick-start)
- [Available Services](#available-services)
- [Common Commands](#common-commands)
- [Benchmarking](#benchmarking)
- [Documentation](#documentation)

---

## Quick Start

```bash
# Start Ollama (recommended for beginners)
./scripts/start-ollama.sh

# Pull and test a model
docker exec -it ollama ollama pull llama3.2:3b
docker exec -it ollama ollama run llama3.2:3b "Hello!"

# Or try vLLM for better performance
./scripts/start-vllm.sh meta-llama/Llama-3.2-3B-Instruct

# Stop everything
./scripts/stop-all.sh
```

---

## Available Services

### Ollama (Recommended for Testing)
**Best for:** Quick model testing, trying different quantizations

```bash
./scripts/start-ollama.sh
docker exec -it ollama ollama pull llama3.1:8b
docker exec -it ollama ollama list
```

**Features:**
- Automatic quantization (Q4, Q5, Q6, Q8)
- Easy model management
- Simple CLI interface
- REST API at `http://localhost:11434`

### vLLM (Best Performance)
**Best for:** High-throughput inference, API serving

```bash
./scripts/start-vllm.sh meta-llama/Llama-3.2-3B-Instruct
./scripts/test-model.sh vllm "What is AI?"
```

**Features:**
- PagedAttention for efficiency
- Continuous batching
- OpenAI-compatible API at `http://localhost:8000`

### Text Generation Inference (TGI)
**Best for:** Production deployments, Hugging Face models

```bash
./scripts/start-tgi.sh meta-llama/Llama-3.2-3B-Instruct
./scripts/test-model.sh tgi "Explain quantum computing"
```

**Features:**
- Token streaming
- Distributed inference
- API at `http://localhost:8080`

---

## Common Commands

### Ollama

```bash
# List installed models
docker exec -it ollama ollama list

# Pull a model
docker exec -it ollama ollama pull llama3.1:8b

# Pull specific quantization
docker exec -it ollama ollama pull llama3.1:8b-q4

# Interactive chat
docker exec -it ollama ollama run llama3.1:8b

# Single query
docker exec -it ollama ollama run llama3.1:8b "Your prompt here"

# Remove model
docker exec -it ollama ollama rm llama3.1:8b
```

### Batch Model Downloads

```bash
./scripts/batch-pull-models.sh small     # 3-8B models
./scripts/batch-pull-models.sh medium    # 14B Q4 models
./scripts/batch-pull-models.sh large     # 70B Q2 models
./scripts/batch-pull-models.sh coding    # Code-focused models
```

### Service Management

```bash
# Check service status
docker compose ps

# View resource usage
docker stats

# View logs
docker compose logs ollama
docker compose logs vllm

# Restart a service
docker compose restart ollama

# Stop all services
./scripts/stop-all.sh
```

---

## Benchmarking

### Quick Test
```bash
./scripts/test-model.sh ollama "Your test prompt"
```

### Single Model Benchmark
```bash
./scripts/benchmark.sh ollama 10
```

### Comprehensive Automated Benchmark
```bash
# Download all benchmark models
./scripts/pull-benchmark-models.sh

# Run full automated benchmark (48 models)
./scripts/run-full-benchmark.sh

# Quick benchmark (skip downloads)
./scripts/run-full-benchmark.sh --skip-pull -y
```

**For detailed benchmarking guide:** See [../../docs/Benchmark_Automation.md](../../docs/Benchmark_Automation.md)

---

## GPU Monitoring

```bash
# Real-time GPU usage
watch -n 1 nvidia-smi

# Detailed metrics
nvidia-smi dmon -i 0 -s pucvmet -d 1

# GPU metrics logger (for benchmarks)
./scripts/gpu-metrics-logger.sh
```

---

## API Examples

### Ollama API
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Why is the sky blue?"
}'
```

### vLLM OpenAI-Compatible API
```bash
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.2-3B-Instruct",
    "prompt": "Why is the sky blue?",
    "max_tokens": 100
  }'
```

---

## Documentation

### Quick References
- **[CHEATSHEET.txt](CHEATSHEET.txt)** - Command reference card
- **[../QUICK_START.md](../QUICK_START.md)** - 5-minute setup guide

### Comprehensive Guides
- **[../docs/Models_And_Benchmarks.md](../docs/Models_And_Benchmarks.md)** - Model selection & performance data
- **[../docs/Benchmark_Automation.md](../docs/Benchmark_Automation.md)** - Automated benchmarking guide
- **[../docs/LLM_System_Setup.md](../docs/LLM_System_Setup.md)** - System prerequisites & driver setup
- **[../docs/LLM_Inference_Setup.md](../docs/LLM_Inference_Setup.md)** - Docker & Ollama configuration
- **[../docs/Install.md](../docs/Install.md)** - Installation walkthrough

### Configuration References
- **[../docs/Model_Guide.md](../docs/Model_Guide.md)** - Model testing strategy
- **[../docs/Dell_T5820_Hardware.md](../docs/Dell_T5820_Hardware.md)** - Hardware specifications

---

## Directory Structure

```
/mnt/llm-models/        # 4TB NVMe - Model storage
├── ollama/              # Ollama models
├── vllm/                # vLLM/HuggingFace cache
└── tgi/                 # TGI cache

/mnt/llm-data/          # 1TB NVMe - Working data
├── benchmarks/          # Performance results
└── logs/                # Service logs

~/llm-docker/           # Docker configs & scripts
├── docker-compose.yml
├── .env
├── scripts/
└── benchmark_results/
```

---

## Troubleshooting

### Common Issues

**Ollama won't start:**
```bash
docker compose logs ollama
./scripts/stop-all.sh && ./scripts/start-ollama.sh
```

**Out of GPU memory:**
```bash
nvidia-smi  # Check VRAM usage
docker exec ollama ollama stop <model-name>
# Try smaller model or Q4 quantization
```

**Service won't start:**
```bash
# Check logs
docker compose logs <service>

# Verify GPU access
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# Restart Docker
sudo systemctl restart docker
```

**Models not downloading:**
```bash
# Check disk space
df -h /mnt/llm-models

# Check Ollama connectivity
curl http://localhost:11434/api/tags
```

**Port already in use:**
```bash
./scripts/stop-all.sh
# Check what's using the port
sudo lsof -i :11434
```

---

## Quick Model Recommendations (RTX 3090 24GB)

| Use Case | Model | VRAM | Speed |
|----------|-------|------|-------|
| **Fastest** | exaone-deep:7.8b | ~5GB | 90.1 tok/s |
| **Testing** | llama3.2:3b | ~3GB | 52.3 tok/s |
| **Daily Use** | qwen3:8b | ~5GB | 62.1 tok/s |
| **Balanced** | llama3.1:8b | ~5GB | 42.8 tok/s |
| **Reasoning** | deepseek-r1:14b | ~9GB | 56.6 tok/s |
| **Coding** | qwen2.5-coder:14b | ~9GB | 29.2 tok/s |
| **Quality** | qwen3:14b | ~9GB | 43.2 tok/s |
| **Max Quality** | qwen2.5:32b | ~19GB | 21.4 tok/s |
| **Vision** | qwen3-vl:8b | ~7GB | 40.9 tok/s |
| **Multilingual** | aya-expanse:8b | ~6GB | 32.0 tok/s |

**See full 48-model benchmark:** [../docs/Models_And_Benchmarks.md](../docs/Models_And_Benchmarks.md)

---

## Resources

- [Ollama Models Library](https://ollama.com/library)
- [vLLM Documentation](https://docs.vllm.ai/)
- [Hugging Face Models](https://huggingface.co/models)
- [Model Quantization Guide](https://huggingface.co/docs/transformers/main/en/quantization)

---

**Pro Tip:** Start with llama3.2:3b to verify everything works, then experiment with larger models and quantizations!
