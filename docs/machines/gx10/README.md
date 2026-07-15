# ASUS Ascent GX10 (NVIDIA GB10) — Machine Guide

Compact ARM AI appliance with a **128 GB unified memory** GB10 Grace Blackwell superchip. Runs
LLMs via **native Ollama** (no Docker). Its whole reason to exist: hosting **70B–120B** models
that a 24 GB discrete GPU cannot hold.

| | |
|---|---|
| CPU | 20-core NVIDIA Grace (ARM `aarch64`) |
| GPU | NVIDIA GB10 (Blackwell, `sm_121`, native FP4) |
| Memory | 128 GB LPDDR5X **unified** (~120 GB usable by GPU) |
| Storage | 3.6 TB NVMe at `/` (models in `/opt/models`) |
| OS | Ubuntu 24.04.4 LTS · Driver 580 · CUDA 13.0 |
| Ollama | **Native** (systemd), port **11500** |

## Docs

- **[Hardware.md](Hardware.md)** — full specs and the trade-offs of unified memory
- **[Setup.md](Setup.md)** — native Ollama config, service management, running big models
- **[Benchmarks.md](Benchmarks.md)** — throughput + head-to-head comparison vs. the RTX 3090

## Fastest path

```bash
cd ~/llm_on_rtx_3090
./setup.sh                                   # verifies ARM + native Ollama environment
ollama list                                  # see installed models
ollama run nemotron-3-nano:30b "Hello!"      # no docker exec needed
```

## Scope

This machine is for **large-model LLM inference**. Image generation (Stable Diffusion / Forge)
is **not** supported here — diffusion is memory-bandwidth bound, and the GB10's ~273 GB/s unified
memory makes it too slow to be worthwhile. Use the [T5820](../t5820/Stable_Diffusion.md) for images.

## Shared references (machine-independent)

- [Model Selection Guide](../../shared/Model_Guide.md)
- [Models & Benchmarks](../../shared/Models_and_Benchmarks.md) — ⚠️ speeds measured on the RTX 3090;
  not directly comparable to the GX10 (see [Setup.md](Setup.md#running-big-models))
- [Benchmark Automation](../../shared/Benchmark_Automation.md)

> See [../../MACHINES.md](../../MACHINES.md) for a side-by-side comparison with the Dell T5820.
