# Local LLM Inference on RTX 3090

Battle-tested guide for local LLM inference on Ubuntu 24.04 with NVIDIA GPU acceleration. From fresh OS install to running 32B parameter models at 97% GPU utilization. Includes Docker GPU runtime fixes, NVMe storage optimization, and Ollama deployment.

---

## 🎯 What This Project Does

This repository provides a complete, production-ready setup for running large language models locally on consumer/workstation NVIDIA GPUs. No cloud costs, no API limits, full privacy.

**Key achievements:**
- ✅ **10 models tested** from 3B to 34B parameters
- ✅ Run 32B parameter models entirely on GPU (no CPU offloading)
- ✅ Achieve 80-97% GPU utilization during inference
- ✅ 15-60 tokens/second depending on model size
- ✅ Proper storage separation (models vs. working data)
- ✅ Docker-based deployment for reproducibility
- ✅ Comprehensive benchmarking suite included

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
docker exec -it ollama ollama pull qwen2.5:14b

# Run inference
docker exec -it ollama ollama run qwen2.5:14b "Explain quantum computing"

# Check GPU utilization
nvidia-smi
```

---

## 📊 Performance Results

Tested on RTX 3090 (24GB VRAM) - **10 models validated**:

| Model | VRAM | GPU Util | Tokens/sec | Best For |
|-------|------|----------|------------|----------|
| llama3.2:3b | ~2GB | 60-80% | 50-60 | Quick responses |
| mistral:7b | ~4GB | 65-85% | 45-55 | General use |
| qwen2.5:7b | ~5GB | 70-85% | 40-50 | Coding |
| llama3.1:8b | ~5GB | 70-85% | 40-50 | Daily driver |
| phi3:14b | ~8GB | 75-90% | 30-40 | Long context (128k) |
| qwen2.5:14b | ~9GB | 80-90% | 30-40 | Production use |
| gemma2:27b | ~15GB | 85-95% | 20-30 | High quality |
| **qwen2.5:32b** | **~21GB** | **80-97%** | **15-25** | **Max quality** |
| codellama:34b | ~18GB | 85-95% | 12-20 | Code generation |
| deepseek-coder:33b | ~17GB | 85-95% | 12-20 | Advanced coding |

📈 **[Full Benchmark Details →](docs/BENCHMARKS.md)** - Task-specific recommendations, quantization analysis, and thermal data.

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
- [Alibaba Cloud](https://www.alibabacloud.com/en/solutions/generative-ai/qwen) - Qwen 2.5 series
- [Mistral AI](https://mistral.ai/) - Mistral 7B
- [Microsoft](https://azure.microsoft.com/en-us/products/phi-3) - Phi-3
- [Google DeepMind](https://deepmind.google/technologies/gemma/) - Gemma 2
- [DeepSeek](https://www.deepseek.com/) - DeepSeek Coder

---

**Questions or issues?** Open an issue on GitHub or check the troubleshooting sections in the setup guides.