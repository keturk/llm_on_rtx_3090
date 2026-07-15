# Local LLM & Image Generation on RTX 3090

Battle-tested guide for local AI inference on Ubuntu 24.04 with NVIDIA GPU acceleration. From fresh OS install to running 32B parameter models at 97% GPU utilization — plus Stable Diffusion image generation on the same card. Includes Docker GPU runtime fixes, NVMe storage optimization, Ollama deployment, and SD WebUI Forge.

---

## 🎯 What This Project Does

This repository provides a complete, production-ready setup for running large language models **and image generation models** locally on consumer/workstation NVIDIA GPUs. No cloud costs, no API limits, full privacy.

**Key achievements:**
- ✅ **59 models documented** from 1.7B to 35B parameters
- ✅ Run 32B parameter models entirely on GPU (no CPU offloading)
- ✅ Achieve 80-97% GPU utilization during inference
- ✅ 17-90 tokens/second depending on model size
- ✅ **Stable Diffusion (SDXL + FLUX) running alongside Ollama on one GPU**
- ✅ Proper storage separation (models vs. working data)
- ✅ Docker-based deployment for reproducibility
- ✅ Comprehensive benchmarking suite included

**🆕 July 2026 Update:** Added 11 new models including Gemma 4, GPT-OSS (OpenAI), Devstral, Mistral Small 3.1/3.2, Qwen 3.5/3.6 — plus a **Stable Diffusion WebUI Forge** image generation server!

---

## 🖥️ Supported Machines

This repo now covers **two** very different NVIDIA machines. Run `./setup.sh` and it auto-detects
which one you're on. Full side-by-side comparison: **[docs/MACHINES.md](docs/MACHINES.md)**.

| Machine | Arch | GPU / Memory | Ollama | Max model | Guide |
|---------|------|--------------|--------|-----------|-------|
| **Dell T5820** (reference) | x86-64 | RTX 3090, 24 GB **discrete** | Docker | ~32B | [machines/t5820/](docs/machines/t5820/README.md) |
| **ASUS Ascent GX10** 🆕 | ARM | GB10 Blackwell, 128 GB **unified** | Native (systemd) | **~120B** | [machines/gx10/](docs/machines/gx10/README.md) |

> Everything below (benchmarks, model tables, Stable Diffusion) was developed on the **T5820 /
> RTX 3090**. The GX10 trades bandwidth for capacity — it runs 70B–120B models the 3090 cannot
> hold, using native Ollama on ARM. See its [Setup guide](docs/machines/gx10/Setup.md).

---

## 🖥️ Reference Hardware (Dell T5820)

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
├── setup.sh                           # 🔎 Machine-detecting setup/verify entry point
├── LICENSE                            # MIT License
├── docs/
│   ├── MACHINES.md                    # 🖥️ Machine comparison & how to pick a path
│   ├── shared/                        # Machine-independent references
│   │   ├── Model_Guide.md             # 🎯 Quick model selection guide (start here!)
│   │   ├── Models_and_Benchmarks.md   # 📊 Benchmark analysis (measured on RTX 3090)
│   │   └── Benchmark_Automation.md    # 🤖 Automated benchmark workflow
│   └── machines/
│       ├── t5820/                     # Dell T5820 + RTX 3090 (x86, Docker)
│       │   ├── README.md              #    Machine landing page
│       │   ├── Hardware.md            #    Hardware specifications
│       │   ├── System_Setup.md        #    Drivers, Docker, NVIDIA toolkit, NVMe
│       │   ├── Inference_Setup.md     #    Ollama (Docker) + Forge configuration
│       │   ├── Install.md             #    Installation walkthrough
│       │   └── Stable_Diffusion.md    #    🎨 Image generation (SD WebUI Forge)
│       └── gx10/                      # ASUS GX10 + GB10 (ARM, native Ollama) 🆕
│           ├── README.md              #    Machine landing page
│           ├── Hardware.md            #    GB10 / unified-memory specs
│           └── Setup.md               #    Native Ollama (systemd) on ARM
└── llm-docker/                        # T5820 Docker deployment (compose, scripts)
    ├── README.md                      # Quick reference & commands
    ├── CHEATSHEET.txt                 # Quick command reference
    ├── .env                           # Environment configuration
    ├── docker-compose.yml             # Ollama service
    ├── docker-compose.forge.yml       # 🆕 Stable Diffusion Forge service
    ├── docker-compose.vllm.yml        # vLLM (optional)
    ├── docker-compose.tgi.yml         # Text Generation Inference (optional)
    ├── forge/                         # 🆕 Forge image build
    │   ├── Dockerfile                 #    CUDA 12.8 + Python 3.12
    │   └── entrypoint.sh              #    venv bootstrap + launch
    ├── scripts/
    │   ├── start-ollama.sh            # Start Ollama service
    │   ├── start-forge.sh             # 🆕 Start Stable Diffusion service
    │   ├── run-full-benchmark.sh      # Automated full benchmark
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
>
> **On the ASUS GX10 (ARM)?** Ollama runs natively there, not in Docker — skip the steps below
> and follow the [GX10 Setup guide](docs/machines/gx10/Setup.md) instead. Or just run
> `./setup.sh`, which detects your machine.

> The steps below are the **Dell T5820 / RTX 3090 (Docker)** path.

### 1. Complete System Setup

Follow the [LLM System Setup Guide](docs/machines/t5820/System_Setup.md) to configure:
- NVIDIA 570-open driver installation
- Docker Engine with NVIDIA Container Toolkit
- NVMe drive mounting and directory structure
- System snapshot with Timeshift

### 2. Deploy Ollama

Follow the [LLM Inference Setup Guide](docs/machines/t5820/Inference_Setup.md) to:
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

### 4. (Optional) Deploy Image Generation

```bash
# Start Stable Diffusion WebUI Forge — takes 5-10 min on first run
./scripts/start-forge.sh

# Open http://localhost:7860
```

See the [Stable Diffusion Guide](docs/machines/t5820/Stable_Diffusion.md) for checkpoint downloads and
VRAM budgeting.

---

## 📊 Performance Results

Tested on RTX 3090 (24GB VRAM) - **59 models documented** (July 2026):

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

### Medium Models (12-20B) — Balanced

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
| gemma4:12b 🆕🆕 | ~7GB | TBD | Google's latest, tool calling |
| gpt-oss:20b 🆕🆕 | ~14GB | TBD | OpenAI MoE, best tool calling |

### Large Models (22-35B) — Maximum Quality

| Model | VRAM | Tokens/sec | Best For |
|-------|------|------------|----------|
| qwen3:30b-a3b 🆕 | ~18GB | 43.7 | MoE - fast for size! |
| codestral:22b | ~13GB | 35.4 | Code specialist |
| nemotron-3-nano:30b | ~23GB | 33.5 | Large efficient |
| exaone-deep:32b 🆕 | ~19GB | 33.3 | Reasoning 32B |
| deepseek-r1:32b 🆕 | ~19GB | 29.8 | Max reasoning quality |
| devstral:24b 🆕🆕 | ~14GB | TBD | SWE-Bench coding champion |
| devstral-small-2:24b 🆕🆕 | ~15GB | TBD | Coding agent, 384K ctx |
| mistral-small3.1:24b 🆕🆕 | ~15GB | TBD | 128K multimodal |
| mistral-small3.2:24b 🆕🆕 | ~15GB | TBD | Function calling |
| gemma4:26b 🆕🆕 | ~18GB | TBD | Google MoE, 4B active |
| gemma4:31b 🆕🆕 | ~20GB | TBD | Google's best dense |
| qwen3.5:27b 🆕🆕 | ~17GB | TBD | Alibaba Feb 2026 |
| qwen3.6:27b 🆕🆕 | ~17GB | TBD | Latest Qwen, 256K ctx |
| qwen3.6:35b 🆕🆕 | ~24GB | TBD | Latest Qwen MoE |
| qwen2.5:32b | ~19GB | 21.4 | Max general quality |
| deepseek-coder:33b | ~18GB | 21.5 | Elite coding |
| gemma3:27b 🆕 | ~17GB | 18.0 | Multimodal large |

🆕 = New in 2025 update | 🆕🆕 = New in July 2026 update

📈 **[Full Model Guide & Benchmarks →](docs/shared/Models_and_Benchmarks.md)** - Complete model selection guide with task-specific recommendations, quantization analysis, and thermal data.

---

## 🆕🆕 July 2026 Model Highlights

### Gemma 4 (Google's Latest)
Google's flagship models with built-in tool calling, vision, and frontier-level reasoning. Available in 12B (compact), 26B MoE (4B active), and 31B dense variants.

```bash
docker exec -it ollama ollama run gemma4:12b "Write a function that validates JSON schema"
docker exec -it ollama ollama run gemma4:31b "Explain the trade-offs between microservices and monoliths"
```

### GPT-OSS (OpenAI's First Open Model)
OpenAI's first open-weight model under Apache 2.0. MoE architecture (21B total, 3.6B active) runs on just 14GB VRAM. Cleanest tool-call JSON of any open model, rivals o3-mini on benchmarks.

```bash
docker exec -it ollama ollama run gpt-oss:20b "Call the weather API for San Francisco and format the response"
```

### Devstral (Mistral Coding Agent)
Mistral x All Hands AI collaboration. SWE-Bench Verified champion at 46.8%. Devstral Small 2 adds 384K context for massive codebases.

```bash
docker exec -it ollama ollama run devstral:24b "Review this code and suggest improvements"
docker exec -it ollama ollama run devstral-small-2:24b "Analyze this repository structure"
```

### Qwen 3.5/3.6 (Alibaba's Latest)
Qwen 3.6 (April 2026) is the best overall pick for 24GB GPUs per community consensus. 256K context, improved coding, and stable responsive experience.

```bash
docker exec -it ollama ollama run qwen3.6:27b "Write a Python async web scraper with error handling"
```

### Mistral Small 3.1/3.2 (Updated Mistral)
Updated Mistral Small with multimodal support and improved function calling. 3.2 adds better instruction following and less repetition.

```bash
docker exec -it ollama ollama run mistral-small3.2:24b "Describe this architecture diagram"
```

---

## 🆕 2025 Model Highlights

### DeepSeek-R1 (Reasoning Models)
Chain-of-thought reasoning models that show their "thinking" process. Performance approaches OpenAI's O1 on many benchmarks. The 14B model achieves 56.6 tok/s — fastest in its quality class.

```bash
docker exec -it ollama ollama run deepseek-r1:14b "Solve: If 3x + 7 = 22, what is x?"
```

### Qwen3 (Next-Gen Qwen)
Major upgrade from Qwen2.5. The 14B runs at 43.2 tok/s vs Qwen2.5:14B at 29.2 tok/s — 48% faster! The 30B MoE model only activates 3B parameters per token, achieving 43.7 tok/s.

```bash
docker exec -it ollama ollama run qwen3:14b "Write a Python async web scraper"
```

### EXAONE-Deep (Speed Champion)
LG's reasoning model with exceptional speed. The 7.8B achieves 90.1 tok/s — fastest in the entire benchmark!

```bash
docker exec -it ollama ollama run exaone-deep:7.8b "Explain quantum entanglement"
```

### Other 2025 Models
- **Gemma3** (4B/12B/27B): Google's multimodal with 128K context
- **GLM4** (9B): Bilingual Chinese-English at 31.4 tok/s
- **Falcon3** (7B/10B): TII's open alternative
- **Aya-Expanse** (8B/32B): Cohere's multilingual models
- **Marco-O1** (7B): Reasoning specialist at 68.9 tok/s

---

## 🎨 Image Generation (Stable Diffusion)

The same RTX 3090 that serves LLMs also runs image generation via
[Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge).

```bash
cd llm-docker
./scripts/start-forge.sh      # http://localhost:7860
```

### Installed Checkpoints

| Checkpoint | Size | VRAM | License | Notes |
|-----------|------|------|---------|-------|
| SDXL base 1.0 | 6.9 GB | ~8 GB | OpenRAIL++-M | Broad style range, huge LoRA ecosystem |
| FLUX.1 schnell (fp8) | 17.2 GB | ~17 GB | **Apache 2.0** | Best prompt-following; 4-step distilled |

> Forge ships with **no weights** — it's just the server. A *checkpoint* (`.safetensors`) is
> the model that actually generates images, exactly like `ollama pull` for LLMs.

### Do Ollama and Forge Conflict?

**No.** Separate ports (11434 / 7860), separate containers, shared `llm-network`. Multiple
CUDA processes hold VRAM on one card simultaneously — the driver handles this natively.

The only constraint is **total VRAM (24 GB)**:

| Combination | Fits? |
|-------------|-------|
| SDXL (~8 GB) + 8B LLM (~5 GB) | ✅ Comfortable |
| SDXL (~8 GB) + 14B LLM (~9 GB) | ✅ Fits |
| FLUX (~17 GB) + 8B LLM (~5 GB) | ⚠️ Tight |
| FLUX (~17 GB) + 32B LLM (~19 GB) | ❌ OOM |

Ollama auto-unloads idle models after 5 minutes. To force it before a heavy image run:

```bash
docker exec ollama ollama stop <model>
```

### Settings Cheat Sheet

SDXL and FLUX need **different** settings — reusing SDXL's for FLUX produces garbage:

| | SDXL | FLUX.1 schnell |
|---|------|----------------|
| Resolution | 1024×1024 | 1024×1024 |
| Sampler | DPM++ 2M Karras | Euler + Simple |
| Steps | 25-30 | **4** (distilled — more is worse) |
| CFG | 6-7 | 1.0 |

🎨 **[Full Stable Diffusion Guide →](docs/machines/t5820/Stable_Diffusion.md)** — checkpoints, LoRAs, API usage, VRAM tuning, and build troubleshooting.

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

- **Ollama** - Primary LLM inference engine with simple model management
- **SD WebUI Forge** - Image generation (SDXL, FLUX) sharing the same GPU
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
| [**Machine Comparison**](docs/MACHINES.md) | **🖥️ T5820 vs GX10 — which path to follow** |
| [**Model Selection Guide**](docs/shared/Model_Guide.md) | **🎯 Which model should I use? (start here!)** |
| [**Models & Benchmarks**](docs/shared/Models_and_Benchmarks.md) | **📊 Benchmark analysis & detailed model info (RTX 3090)** |
| [Benchmark Automation](docs/shared/Benchmark_Automation.md) | Automated benchmarking workflow |

### Dell T5820 (RTX 3090, Docker)
| Document | Description |
|----------|-------------|
| [T5820 Guide](docs/machines/t5820/README.md) | Machine landing page |
| [**Stable Diffusion Guide**](docs/machines/t5820/Stable_Diffusion.md) | **🎨 Image generation — Forge, checkpoints, VRAM sharing** |
| [Installation Guide](docs/machines/t5820/Install.md) | Step-by-step installation walkthrough |
| [LLM System Setup](docs/machines/t5820/System_Setup.md) | Complete OS and driver configuration |
| [LLM Inference Setup](docs/machines/t5820/Inference_Setup.md) | Ollama + Forge deployment and optimization |
| [Hardware Specifications](docs/machines/t5820/Hardware.md) | Dell T5820 hardware details |

### ASUS GX10 (GB10, native Ollama) 🆕
| Document | Description |
|----------|-------------|
| [GX10 Guide](docs/machines/gx10/README.md) | Machine landing page |
| [GX10 Setup](docs/machines/gx10/Setup.md) | Native Ollama (systemd) on ARM, big models |
| [GX10 Benchmarks](docs/machines/gx10/Benchmarks.md) | Throughput + head-to-head vs. RTX 3090 |
| [Hardware Specifications](docs/machines/gx10/Hardware.md) | GB10 / unified-memory details |

---

## ⚠️ Important Notes

- **VRAM is the bottleneck** - Model size is limited by GPU memory, not system RAM
- **Quantization matters** - Q4 quantization allows larger models with minimal quality loss
- **Thermal management** - Monitor GPU temperature during extended inference sessions
- **Storage speed** - NVMe recommended for fast model loading (especially 19GB+ models)
- **Sharing the GPU** - Ollama and Forge coexist fine, but their VRAM *adds up*. Unload large LLMs (`docker exec ollama ollama stop <model>`) before running FLUX

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
- [Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge) - Image generation UI & API
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit) - GPU support in Docker

**Model Providers:**
- [Meta AI](https://ai.meta.com/) - Llama 3.1, Llama 3.2, Code Llama
- [Alibaba Cloud](https://www.alibabacloud.com/en/solutions/generative-ai/qwen) - Qwen 2.5, Qwen 3, Qwen 3.5, Qwen 3.6, Qwen3-VL series
- [Mistral AI](https://mistral.ai/) - Mistral 7B, Ministral-3, Codestral, Mistral Small 3.1/3.2, Devstral
- [Microsoft](https://azure.microsoft.com/en-us/products/phi-3) - Phi-3, Phi-4 series
- [Google DeepMind](https://deepmind.google/technologies/gemma/) - Gemma 2, Gemma 3, Gemma 4
- [OpenAI](https://openai.com/) - GPT-OSS
- [DeepSeek](https://www.deepseek.com/) - DeepSeek Coder, DeepSeek-R1
- [LG AI Research](https://www.lgresearch.ai/) - EXAONE-Deep
- [TII UAE](https://www.tii.ae/) - Falcon3
- [Cohere](https://cohere.com/) - Aya-Expanse
- [Zhipu AI](https://www.zhipuai.cn/) - GLM4
- [HuggingFace](https://huggingface.co/) - SmolLM2
- [Allen Institute for AI](https://allenai.org/) - OLMo2
- [All Hands AI](https://www.all-hands.dev/) - Devstral (with Mistral AI)

**Image Model Providers:**
- [Stability AI](https://stability.ai/) - SDXL
- [Black Forest Labs](https://blackforestlabs.ai/) - FLUX.1 schnell

---

**Questions or issues?** Open an issue on GitHub or check the troubleshooting sections in the setup guides.
