# LLM Docker Testing Environment

Quick reference for testing different LLM inference engines on your Dell T5820 with RTX 3090.

## Quick Start

```bash
# Start Ollama (easiest to get started)
./scripts/start-ollama.sh

# Pull and test a model
docker exec -it ollama ollama pull llama3.2:3b
docker exec -it ollama ollama run llama3.2:3b "Hello!"

# Or use vLLM for better performance
./scripts/start-vllm.sh meta-llama/Llama-3.2-3B-Instruct

# Stop everything
./scripts/stop-all.sh
```

## Directory Structure

```
/mnt/llm-models/        # 4TB NVMe - Model storage
├── ollama/              # Ollama models
├── vllm/                # vLLM/HuggingFace cache
└── tgi/                 # TGI cache

/mnt/llm-data/         # 1TB NVMe - Working data
├── benchmarks/          # Performance results
└── logs/                # Service logs

~/llm-docker/            # Docker configs & scripts
├── docker-compose.yml
├── .env
└── scripts/
```

## Available Services

### Ollama (Recommended for Testing)
- **Best for**: Quick model testing, trying different quantizations
- **Models**: Supports Llama, Mistral, Qwen, Phi, Gemma, and more
- **Quantizations**: Automatic - Q4_0, Q4_K_M, Q5_K_M, Q6_K, Q8_0

```bash
./scripts/start-ollama.sh
docker exec -it ollama ollama pull llama3.1:8b      # Full precision
docker exec -it ollama ollama pull llama3.1:8b-q4   # 4-bit quantized
docker exec -it ollama ollama list                   # See installed models
```

### vLLM (Best Performance)
- **Best for**: High-throughput inference, API serving
- **Features**: PagedAttention, continuous batching
- **API**: OpenAI-compatible

```bash
./scripts/start-vllm.sh meta-llama/Llama-3.2-3B-Instruct
./scripts/test-model.sh vllm "What is AI?"
```

### Text Generation Inference (TGI)
- **Best for**: Production deployments, Hugging Face models
- **Features**: Token streaming, distributed inference

```bash
./scripts/start-tgi.sh meta-llama/Llama-3.2-3B-Instruct
./scripts/test-model.sh tgi "Explain quantum computing"
```

## Model Recommendations for RTX 3090 (24GB)

| Model Size | Quantization | VRAM Usage | Quality | Speed |
|------------|-------------|------------|---------|-------|
| 3B         | Full (FP16) | ~6 GB      | Good    | Fast  |
| 8B         | Full (FP16) | ~16 GB     | Better  | Med   |
| 8B         | Q4          | ~5 GB      | Good    | Fast  |
| 14B        | Q4          | ~8 GB      | Better  | Med   |
| 30B        | Q4          | ~16 GB     | Great   | Slow  |
| 70B        | Q2          | ~19 GB     | Good    | Slow  |
| 70B        | Q4          | Too large  | N/A     | N/A   |

## Common Commands

### Ollama
```bash
# List available models online
docker exec -it ollama ollama list

# Pull specific quantization
docker exec -it ollama ollama pull llama3.1:70b-q2

# Interactive chat
docker exec -it ollama ollama run llama3.1:8b

# Remove model
docker exec -it ollama ollama rm llama3.1:8b
```

### Testing & Benchmarking
```bash
# Quick test
./scripts/test-model.sh ollama "What is the meaning of life?"

# Run benchmark
./scripts/benchmark.sh ollama 20

# View logs
docker compose logs ollama
docker compose logs vllm
```

### Managing Services
```bash
# Check status
docker compose ps

# View resource usage
docker stats

# Restart a service
docker compose --profile ollama restart

# Stop all services
./scripts/stop-all.sh
```

## GPU Monitoring

```bash
# Watch GPU usage in real-time
watch -n 1 nvidia-smi

# Detailed GPU info
nvidia-smi dmon -i 0 -s pucvmet -d 1
```

## Testing Different Quantizations

Ollama makes this super easy:

```bash
# Test different quantizations of same model
docker exec -it ollama ollama pull llama3.1:8b      # Full precision
docker exec -it ollama ollama pull llama3.1:8b-q4   # 4-bit
docker exec -it ollama ollama pull llama3.1:8b-q2   # 2-bit

# Compare quality
./scripts/benchmark.sh ollama 10  # Run before each pull
```

## Troubleshooting

### Out of Memory
```bash
# Check GPU memory
nvidia-smi

# Reduce GPU memory utilization in .env
GPU_MEMORY_UTILIZATION=0.85  # Default is 0.90
```

### Service Won't Start
```bash
# Check logs
docker compose logs <service>

# Verify GPU access
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# Restart Docker
sudo systemctl restart docker
```

### Models Not Downloading
```bash
# Check disk space
df -h /mnt/llm-models

# Manually pull Hugging Face model
docker exec -it vllm bash
huggingface-cli download meta-llama/Llama-3.2-3B-Instruct
```

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

## Next Steps

1. **Start with Ollama**: Easy to test multiple models quickly
2. **Try different quantizations**: Compare quality vs speed vs memory
3. **Benchmark**: Use `benchmark.sh` to measure performance
4. **Scale up**: Try larger models with aggressive quantization
5. **Optimize**: Tune `GPU_MEMORY_UTILIZATION` for your workload

## Resources

- [Ollama Models](https://ollama.com/library)
- [vLLM Documentation](https://docs.vllm.ai/)
- [Hugging Face Models](https://huggingface.co/models)
- [Model Quantization Guide](https://huggingface.co/docs/transformers/main/en/quantization)
