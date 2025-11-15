# Local LLM Inference on RTX 3090

Battle-tested guide for local LLM inference on Ubuntu 24.04 with NVIDIA GPU acceleration. From fresh OS install to running 32B parameter models at 97% GPU utilization. Includes Docker GPU runtime fixes, NVMe storage optimization, and Ollama deployment.

---

## 🎯 What This Project Does

This repository provides a complete, production-ready setup for running large language models locally on consumer/workstation NVIDIA GPUs. No cloud costs, no API limits, full privacy.

**Key achievements:**
- ✅ Run 32B parameter models entirely on GPU (no CPU offloading)
- ✅ Achieve 80-97% GPU utilization during inference
- ✅ 15-25 tokens/second on complex reasoning tasks
- ✅ Proper storage separation (models vs. working data)
- ✅ Docker-based deployment for reproducibility

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
│   └── Dell_T5820_Hardware.md         # Hardware specifications
└── llm-docker/
    ├── .env                           # Environment configuration
    ├── docker-compose.yml             # Ollama service
    ├── docker-compose.vllm.yml        # vLLM (optional)
    ├── docker-compose.tgi.yml         # Text Generation Inference (optional)
    ├── scripts/
    │   ├── start-ollama.sh            # Start Ollama service
    │   ├── stop-all.sh                # Stop all services
    │   ├── benchmark.sh               # Performance testing
    │   └── ...
    ├── configs/
    │   └── MODEL_GUIDE.md             # Model recommendations
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

Tested on RTX 3090 (24GB VRAM):

| Model           | VRAM Usage | GPU Utilization | Tokens/sec | Quality   |
|-----------------|------------|-----------------|------------|-----------|
| llama3.2:3b     | ~2GB       | 60-80%          | 50-60      | Good      |
| llama3.1:8b     | ~5GB       | 70-85%          | 40-50      | Very Good |
| qwen2.5:14b     | ~9GB       | 80-90%          | 30-40      | Excellent |
| **qwen2.5:32b** | **~21GB**  | **80-97%**      | **15-25**  | **Best**  |

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

---

**Questions or issues?** Open an issue on GitHub or check the troubleshooting sections in the setup guides.
