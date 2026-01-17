# Local LLM Inference on RTX 3090

Battle-tested guide for local LLM inference on Ubuntu 24.04 with NVIDIA GPU acceleration. From fresh OS install to running 32B parameter models at 97% GPU utilization. Includes Docker GPU runtime fixes, NVMe storage optimization, and Ollama deployment.

---

## 🎯 What This Project Does

This repository provides a complete, production-ready setup for running large language models locally on consumer/workstation NVIDIA GPUs. No cloud costs, no API limits, full privacy.

**Key achievements:**
- ✅ **48 models tested** from 1.7B to 34B parameters
- ✅ Run 32B parameter models entirely on GPU (no CPU offloading)
- ✅ Achieve 80-97% GPU utilization during inference
- ✅ 17-90 tokens/second depending on model size
- ✅ Proper storage separation (models vs. working data)
- ✅ Docker-based deployment for reproducibility
- ✅ Comprehensive benchmarking suite included

**🆕 January 2026 Update:** Tested 48 models including DeepSeek-R1, Qwen3, Qwen3-VL, Gemma3, GLM4, EXAONE-Deep, Falcon3, and Aya-Expanse!

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
├── QUICK_START.md                     # 🚀 5-minute setup guide (start here!)
├── LICENSE                            # MIT License
├── docs/
│   ├── Model_Guide.md                 # 🎯 Quick model selection guide (start here!)
│   ├── Models_And_Benchmarks.md       # 📊 Complete benchmark analysis & model details
│   ├── Benchmark_Automation.md        # 🤖 Automated benchmark workflow
│   ├── Install.md                     # 💿 Installation walkthrough
│   ├── LLM_System_Setup.md            # System prerequisites & drivers
│   ├── LLM_Inference_Setup.md         # Docker & Ollama configuration
│   └── Dell_T5820_Hardware.md         # Hardware specifications
└── llm-docker/
    ├── README.md                      # Quick reference & commands
    ├── CHEATSHEET.txt                 # Quick command reference
    ├── .env                           # Environment configuration
    ├── docker-compose.yml             # Ollama service
    ├── docker-compose.vllm.yml        # vLLM (optional)
    ├── docker-compose.tgi.yml         # Text Generation Inference (optional)
    ├── scripts/
    │   ├── start-ollama.sh            # Start Ollama service
    │   ├── run-full-benchmark.sh      # 🆕 Automated full benchmark
    │   ├── comprehensive-benchmark.sh # Full benchmark suite
    │   ├── pull-benchmark-models.sh   # Download test models
    │   ├── benchmark.sh               # Basic performance testing
    │   └── ...
    ├── configs/
    │   └── Model_Guide.md             # Model testing strategy
    └── benchmark_results/             # Generated benchmark data
```

---

## 🚀 Quick Start

> **New User?** See [QUICK_START.md](QUICK_START.md) for a 5-minute setup guide!

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

# Run automated benchmarks
./scripts/run-full-benchmark.sh

# Check GPU utilization
nvidia-smi
```

---

## 📊 Performance Results

Tested on RTX 3090 (24GB VRAM) - **48 models validated** (January 2026):

### Small Models (1.7-8B) — Fast Responses

| Model | VRAM | Tokens/sec | Best For |
|-------|------|------------|----------|
| exaone-deep:7.8b 🆕 | ~5GB | 90.1 | Fastest overall! |
| marco-o1:7b 🆕 | ~5GB | 68.9 | Reasoning specialist |
| granite3.1-moe:3b | ~2GB | 65.7 | Tiny MoE powerhouse |
| smollm2:1.7b 🆕 | ~3GB | 64.6 | Smallest, very efficient |
| mistral:7b | ~5GB | 64.7 | General purpose speed |
| phi4-mini | ~3GB | 63.2 | Compact quality |
| qwen3:8b 🆕 | ~5GB | 62.1 | Next-gen balanced |
| deepseek-r1:8b 🆕 | ~5GB | 60.9 | Reasoning 8B |
| llama3.2:3b | ~3GB | 52.3 | Quick testing |
| llama3.1:8b | ~5GB | 42.8 | Daily driver |
| falcon3:7b 🆕 | ~5GB | 41.8 | Open alternative |
| qwen3-vl:8b 🆕 | ~7GB | 40.9 | Vision + text |
| hermes3:8b 🆕 | ~5GB | 38.2 | Conversational |
| qwen2.5:7b | ~5GB | 34.7 | Balanced quality |
| aya-expanse:8b 🆕 | ~6GB | 32.0 | Multilingual |
| glm4:9b 🆕 | ~5GB | 31.4 | Chinese-English |
| gemma3:4b 🆕 | ~4GB | 27.7 | Multimodal compact |

### Medium Models (12-14B) — Balanced

| Model | VRAM | Tokens/sec | Best For |
|-------|------|------------|----------|
| deepseek-r1:14b 🆕 | ~9GB | 56.6 | Best reasoning value |
| qwen3:14b 🆕 | ~9GB | 43.2 | High quality next-gen |
| phi3:14b | ~9GB | 38.7 | Long context (128k) |
| falcon3:10b 🆕 | ~7GB | 37.2 | Open medium |
| phi4 | ~10GB | 34.1 | Latest Microsoft |
| olmo2:13b 🆕 | ~11GB | 33.9 | Open research |
| qwen2.5-coder:14b | ~9GB | 29.2 | Coding specialist |
| qwen2.5:14b | ~9GB | 29.2 | Production use |
| ministral-3:14b | ~10GB | 23.1 | Mistral medium |
| gemma3:12b 🆕 | ~9GB | 22.0 | Multimodal balanced |

### Large Models (22-34B) — Maximum Quality

| Model | VRAM | Tokens/sec | Best For |
|-------|------|------------|----------|
| qwen3:30b-a3b 🆕 | ~18GB | 43.7 | MoE - fast for size! |
| codestral:22b | ~13GB | 35.4 | Code specialist |
| nemotron-3-nano:30b | ~23GB | 33.5 | Large efficient |
| exaone-deep:32b 🆕 | ~19GB | 33.3 | Reasoning 32B |
| qwq:32b | ~19GB | 30.2 | Deep reasoning |
| deepseek-r1:32b 🆕 | ~19GB | 29.8 | Max reasoning quality |
| qwen3-coder:30b 🆕 | ~18GB | 24.3 | Advanced coding |
| codellama:34b | ~19GB | 23.9 | Code generation |
| qwen3-vl:32b 🆕 | ~23GB | 22.1 | Vision + text large |
| qwen2.5:32b | ~19GB | 21.4 | Max general quality |
| deepseek-coder:33b | ~18GB | 21.5 | Elite coding |
| aya-expanse:32b 🆕 | ~20GB | 20.9 | Multilingual large |
| gemma2:27b | ~17GB | 20.4 | Google's best |
| gemma3:27b 🆕 | ~17GB | 18.0 | Multimodal large |

🆕 = New in 2025/2026 update

📈 **[Full Model Guide & Benchmarks →](docs/Models_And_Benchmarks.md)** - Complete model selection guide with task-specific recommendations, quantization analysis, and thermal data.

---

## 🆕 2025/2026 Model Highlights

### DeepSeek-R1 (Reasoning Models)
Chain-of-thought reasoning models that show their "thinking" process. Performance approaches OpenAI's O1 on many benchmarks. The 14B model achieves 56.6 tok/s — fastest in its quality class.

```bash
docker exec -it ollama ollama run deepseek-r1:14b "Solve: If 3x + 7 = 22, what is x?"
# Shows: Thinking... [step-by-step reasoning] ...done thinking.
```

### Qwen3 (Next-Gen Qwen)
Major upgrade from Qwen2.5. The 14B runs at 43.2 tok/s vs Qwen2.5:14B at 29.2 tok/s — 48% faster! The 30B MoE model only activates 3B parameters per token, achieving 43.7 tok/s. Includes vision models (qwen3-vl) and coding specialists.

```bash
docker exec -it ollama ollama run qwen3:14b "Write a Python async web scraper"
docker exec -it ollama ollama run qwen3-vl:8b "Describe this image"
```

### EXAONE-Deep (Speed Champion)
LG's reasoning model with exceptional speed. The 7.8B achieves 90.1 tok/s — fastest in the entire benchmark! The 32B version maintains 33.3 tok/s with deep reasoning capabilities.

```bash
docker exec -it ollama ollama run exaone-deep:7.8b "Explain quantum entanglement"
```

### Gemma3 (Multimodal)
Google's latest with text + image understanding and 128K context window. The 12B model uses ~9GB VRAM vs Gemma2:27B at ~17GB — similar quality at much lower resource usage.

```bash
docker exec -it ollama ollama run gemma3:12b "Describe the key features of transformer architecture"
```

### Other Notable Models
- **GLM4** (9B): Bilingual Chinese-English model at 31.4 tok/s
- **Falcon3** (7B/10B): TII's open alternative, solid performance
- **Aya-Expanse** (8B/32B): Cohere's multilingual models
- **Marco-O1** (7B): Reasoning specialist at 68.9 tok/s
- **SmolLM2** (1.7B): Smallest model with 64.6 tok/s
- **OLMo2** (13B): AI2's fully open research model

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

### Quick Start Guides
| Document | Description |
|----------|-------------|
| [**QUICK_START.md**](QUICK_START.md) | **🚀 5-minute setup guide (start here!)** |
| [Cheatsheet](llm-docker/CHEATSHEET.txt) | Quick reference commands |
| [llm-docker README](llm-docker/README.md) | Command reference & troubleshooting |

### Comprehensive Guides
| Document | Description |
|----------|-------------|
| [**Model Selection Guide**](docs/Model_Guide.md) | **🎯 Which model should I use? (start here!)** |
| [**Models & Benchmarks**](docs/Models_And_Benchmarks.md) | **📊 Complete benchmark analysis & detailed model info** |
| [Benchmark Automation](docs/Benchmark_Automation.md) | Automated benchmarking workflow |
| [Installation Guide](docs/Install.md) | Step-by-step installation walkthrough |
| [LLM System Setup](docs/LLM_System_Setup.md) | Complete OS and driver configuration |
| [LLM Inference Setup](docs/LLM_Inference_Setup.md) | Ollama deployment and optimization |
| [Hardware Specifications](docs/Dell_T5820_Hardware.md) | Dell T5820 hardware details |

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

**Model Providers:**
- [Meta AI](https://ai.meta.com/) - Llama 3.1, Llama 3.2, Code Llama
- [Alibaba Cloud](https://www.alibabacloud.com/en/solutions/generative-ai/qwen) - Qwen 2.5, Qwen 3, Qwen3-VL series
- [Mistral AI](https://mistral.ai/) - Mistral 7B, Ministral-3, Codestral
- [Microsoft](https://azure.microsoft.com/en-us/products/phi-3) - Phi-3, Phi-4 series
- [Google DeepMind](https://deepmind.google/technologies/gemma/) - Gemma 2, Gemma 3
- [DeepSeek](https://www.deepseek.com/) - DeepSeek Coder, DeepSeek-R1
- [LG AI Research](https://www.lgresearch.ai/) - EXAONE-Deep
- [TII UAE](https://www.tii.ae/) - Falcon3
- [Cohere](https://cohere.com/) - Aya-Expanse
- [Zhipu AI](https://www.zhipuai.cn/) - GLM4
- [HuggingFace](https://huggingface.co/) - SmolLM2
- [Allen Institute for AI](https://allenai.org/) - OLMo2

---

**Questions or issues?** Open an issue on GitHub or check the troubleshooting sections in the setup guides.
