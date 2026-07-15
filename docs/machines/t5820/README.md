# Dell Precision T5820 (RTX 3090) — Machine Guide

x86 workstation with a discrete **24 GB RTX 3090**. Runs LLMs via **Ollama in Docker**, plus
Stable Diffusion image generation on the same card. This is the repo's original reference
machine — all benchmark numbers in the shared docs were measured here.

| | |
|---|---|
| CPU | Intel Xeon W-2235 (x86-64) |
| GPU | NVIDIA RTX 3090, 24 GB GDDR6X (discrete) |
| Memory | 128 GB DDR4 + 24 GB VRAM |
| Storage | `/mnt/llm-models` (4 TB) + `/mnt/llm-data` (1 TB) |
| OS | Ubuntu 24.04 · Driver 570-open · CUDA 12.8 |
| Ollama | **Docker** container, port **11434** |
| Max model | ~32B (Q4) |

## Docs

- **[Hardware.md](Hardware.md)** — full hardware specifications
- **[System_Setup.md](System_Setup.md)** — driver, Docker, NVIDIA Container Toolkit, NVMe mounts
- **[Inference_Setup.md](Inference_Setup.md)** — Ollama (Docker) + GPU optimization + Forge
- **[Install.md](Install.md)** — step-by-step installation walkthrough
- **[Stable_Diffusion.md](Stable_Diffusion.md)** — SD WebUI Forge (SDXL, FLUX) on the same GPU

## Fastest path

```bash
cd llm-docker
./setup.sh
./scripts/start-ollama.sh
docker exec -it ollama ollama run llama3.2:3b "Hello!"
```

## Shared references (machine-independent)

- [Model Selection Guide](../../shared/Model_Guide.md)
- [Models & Benchmarks](../../shared/Models_and_Benchmarks.md) — benchmarked on this machine
- [Benchmark Automation](../../shared/Benchmark_Automation.md)

> See [../../MACHINES.md](../../MACHINES.md) for a side-by-side comparison with the ASUS GX10.
