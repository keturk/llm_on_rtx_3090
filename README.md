# Local LLM Inference on RTX 3090

Battle-tested guide for local LLM inference on Ubuntu 24.04 with NVIDIA GPU acceleration. From fresh OS install to running 32B parameter models at 97% GPU utilization. Includes Docker GPU runtime fixes, NVMe storage optimization, and Ollama deployment.

---

## 🎯 What This Project Does

This repository provides a complete, production-ready setup for running large language models locally on consumer/workstation NVIDIA GPUs. No cloud costs, no API limits, full privacy.

**Key achievements:**
- ✅ **20 models tested** from 3B to 34B parameters
- ✅ Run 32B parameter models entirely on GPU (no CPU offloading)
- ✅ Achieve 80-97% GPU utilization during inference
- ✅ 15-65 tokens/second depending on model size
- ✅ Proper storage separation (models vs. working data)
- ✅ Docker-based deployment for reproducibility
- ✅ Comprehensive benchmarking suite included

**🆕 December 2025 Update:** Added DeepSeek-R1, Qwen3, and Gemma3 model families!

---

## 🖥️ Reference Hardware

This guide was developed and tested on:

```
CPU:     Intel Xeon W-2235 (6 cores / 12 threads, 3.8-4.6 GHz)
RAM:     128 GB DDR4 ECC (2x64 GB, 2666 MHz)
GPU:     NVIDIA RTX 3090 (24 GB GDDR6X)
Storage: 128GB SSD (OS) + 1TB NVMe (data) + 4TB NVMe (models)
OS:      Ubuntu 24.04.3 LTS
```

**Adaptable to:** Any system with an NVIDIA GPU (16GB+ VRAM recommended), 32GB+ RAM, and Ubuntu 22.04/24.04.

---

## 📁 Repository Structure

```
llm_on_rtx_3090/
├── README.md                          # You are here
├── LICENSE                            # MIT License
├── docs/
│   ├── LLM_System_Setup.md            # Base system configuration
│   ├── LLM_Inference_Setup.md         # Ollama & model setup
│   ├── BENCHMARKS.md                  # Comprehensive performance results
│   └── Dell_T5820_Hardware.md         # Hardware specifications
└── llm-docker/
    ├── .env                           # Environment configuration
    ├── docker-compose.yml             # Ollama service
    ├── docker-compose.vllm.yml        # vLLM (optional)
    ├── docker-compose.tgi.yml         # Text Generation Inference (optional)
    ├── scripts/
    │   ├── start-ollama.sh            # Start Ollama service
    │   ├── stop-all.sh                # Stop all services
    │   ├── benchmark.sh               # Basic performance testing
    │   ├── comprehensive-benchmark.sh # Full benchmark suite
    │   ├── pull-benchmark-models.sh   # Download test models
    │   └── ...
    ├── configs/
    │   └── MODEL_GUIDE.md             # Model recommendations
    ├── benchmark_results/             # Generated benchmark data
    └── CHEATSHEET.txt                 # Quick reference commands
```

---

## 🚀 Quick Start

### 1. Complete System Setup

Follow the [LLM System Setup Guide](docs/LLM_System_Setup.md) to configure:
- NVIDIA 570-open driver installation
- Docker Engine with NVIDIA Container Toolkit
- NVMe drive mounting and directory structure
- System snapshot with Timeshift

### 2. Deploy Ollama

Follow the [LLM Inference Setup Guide](docs/LLM_Inference_Setup.md) to:
- Configure Docker Compose for GPU inference
- Pull and test models
- Benchmark performance
- Create golden system snapshot

### 3. Start Using Models

```bash
# Start Ollama
cd llm-docker
./scripts/start-ollama.sh

# Pull a model
docker exec -it ollama ollama pull qwen3:14b

# Run inference
docker exec -it ollama ollama run qwen3:14b "Explain quantum computing"

# Try reasoning model (shows thinking process!)
docker exec -it ollama ollama run deepseek-r1:14b "What is 15% of 847? Think step by step."

# Check GPU utilization
nvidia-smi
```

---

## 📊 Performance Results

Tested on RTX 3090 (24GB VRAM) - **20 models validated**:

### Small Models (3-8B) — Fast Responses

| Model | VRAM | Tokens/sec | Best For |
|-------|------|------------|----------|
| llama3.2:3b | ~2GB | 50-60 | Quick responses, testing |
| gemma3:4b 🆕 | ~3GB | 50-60 | Multimodal, efficient |
| mistral:7b | ~4GB | 45-55 | General use |
| qwen2.5:7b | ~5GB | 40-50 | Coding |
| llama3.1:8b | ~5GB | 40-50 | Daily driver |
| qwen3:8b 🆕 | ~5GB | 40-50 | Next-gen quality |
| deepseek-r1:8b 🆕 | ~5GB | 40-50 | Reasoning |

### Medium Models (12-14B) — Balanced

| Model | VRAM | Tokens/sec | Best For |
|-------|------|------------|----------|
| phi3:14b | ~8GB | 30-40 | Long context (128k) |
| gemma3:12b 🆕 | ~8GB | 30-40 | Multimodal balanced |
| qwen2.5:14b | ~9GB | 30-40 | Production use |
| qwen3:14b 🆕 | ~9GB | 30-40 | High quality |
| deepseek-r1:14b 🆕 | ~9GB | 25-35 | Best reasoning value |
| qwen2.5-coder:14b | ~9GB | 30-40 | Coding specialist |

### Large Models (27-34B) — Maximum Quality

| Model | VRAM | Tokens/sec | Best For |
|-------|------|------------|----------|
| gemma2:27b | ~15GB | 20-30 | High quality |
| gemma3:27b 🆕 | ~17GB | 20-30 | Multimodal large |
| qwen3:30b-a3b 🆕 | ~18GB | 20-30 | MoE, fast for size |
| deepseek-coder:33b | ~17GB | 12-20 | Advanced coding |
| codellama:34b | ~18GB | 12-20 | Code generation |
| **qwen2.5:32b** | **~21GB** | **15-25** | **Max general quality** |
| **deepseek-r1:32b** 🆕 | **~19GB** | **15-20** | **Max reasoning quality** |

🆕 = New in December 2025 update

📈 **[Full Benchmark Details →](docs/BENCHMARKS.md)** - Task-specific recommendations, quantization analysis, and thermal data.

---

## 🆕 2025 Model Highlights

### DeepSeek-R1 (Reasoning Models)
Chain-of-thought reasoning models that show their "thinking" process. Performance approaches OpenAI's O1 on many benchmarks.

```bash
docker exec -it ollama ollama run deepseek-r1:14b "Solve: If 3x + 7 = 22, what is x?"
# Shows: Thinking... [step-by-step reasoning] ...done thinking.
```

### Qwen3 (Next-Gen Qwen)
Major upgrade from Qwen2.5. The 4B model rivals Qwen2.5-72B on many tasks!

```bash
docker exec -it ollama ollama run qwen3:14b "Write a Python async web scraper"
```

### Gemma3 (Multimodal)
Google's latest with text + image understanding and 128K context window.

```bash
docker exec -it ollama ollama run gemma3:12b "Describe the key features of transformer architecture"
```

---

## 🔧 Key Problems Solved

### 1. Docker GPU Runtime Configuration
**Problem:** Models running on CPU instead of GPU despite `--gpus all` flag.

**Solution:** Use `runtime: nvidia` in docker-compose.yml instead of `deploy:` syntax, with explicit NVIDIA environment variables.

```yaml
services:
  ollama:
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility
```

### 2. Storage Organization
**Problem:** Models cluttering system drive, no separation of concerns.

**Solution:** Dedicated NVMe drives mounted at `/mnt/llm-models` (4TB) and `/mnt/llm-data` (1TB) with fstab entries using `nofail` flag.

### 3. Model Size Selection
**Problem:** Attempting to run 70B+ models on 24GB VRAM causes CPU offloading and terrible performance.

**Solution:** Maximum model size for RTX 3090 is ~32B parameters (Q4 quantization). Larger models require multiple GPUs.

---

## 🛠️ Included Tools

- **Ollama** - Primary inference engine with simple model management
- **vLLM** - High-performance inference (optional, for advanced use)
- **TGI** - Text Generation Inference by Hugging Face (optional)
- **Benchmark scripts** - Automated performance testing
- **Health check scripts** - System verification tools

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [LLM System Setup](docs/LLM_System_Setup.md) | Complete OS and driver configuration |
| [LLM Inference Setup](docs/LLM_Inference_Setup.md) | Ollama deployment and optimization |
| [**Performance Benchmarks**](docs/BENCHMARKS.md) | **Comprehensive model testing results** |
| [Hardware Specifications](docs/Dell_T5820_Hardware.md) | Dell T5820 hardware details |
| [Model Guide](llm-docker/configs/MODEL_GUIDE.md) | Recommended models by use case |
| [Cheatsheet](llm-docker/CHEATSHEET.txt) | Quick reference commands |

---

## ⚠️ Important Notes

- **VRAM is the bottleneck** - Model size is limited by GPU memory, not system RAM
- **Quantization matters** - Q4 quantization allows larger models with minimal quality loss
- **Thermal management** - Monitor GPU temperature during extended inference sessions
- **Storage speed** - NVMe recommended for fast model loading (especially 19GB+ models)

---

## 🤝 Contributing

Contributions welcome! Areas of interest:
- Tested configurations on different hardware
- Additional inference engine configurations
- Performance optimization tips
- Documentation improvements

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai/) - Simplified local LLM deployment
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit) - GPU support in Docker
- Ubuntu and the open-source community

**Model Providers:**
- [Meta AI](https://ai.meta.com/) - Llama 3.1, Llama 3.2, Code Llama
- [Alibaba Cloud](https://www.alibabacloud.com/en/solutions/generative-ai/qwen) - Qwen 2.5, Qwen 3 series
- [Mistral AI](https://mistral.ai/) - Mistral 7B
- [Microsoft](https://azure.microsoft.com/en-us/products/phi-3) - Phi-3
- [Google DeepMind](https://deepmind.google/technologies/gemma/) - Gemma 2, Gemma 3
- [DeepSeek](https://www.deepseek.com/) - DeepSeek Coder, DeepSeek-R1

---

**Questions or issues?** Open an issue on GitHub or check the troubleshooting sections in the setup guides.
