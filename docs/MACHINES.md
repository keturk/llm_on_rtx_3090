# Supported Machines

This repo documents local LLM inference across two very different NVIDIA machines. They share
the same *goals* (run models locally, benchmark them) but differ fundamentally in architecture,
memory model, and how Ollama is deployed. Pick your machine below.

| | **Dell T5820** | **ASUS Ascent GX10** |
|---|---|---|
| Guide | [machines/t5820/](machines/t5820/README.md) | [machines/gx10/](machines/gx10/README.md) |
| CPU ISA | x86-64 (Intel Xeon W-2235) | **ARM aarch64** (NVIDIA Grace, 20-core) |
| GPU | RTX 3090 (Ampere) | GB10 (Blackwell, `sm_121`, FP4) |
| GPU memory | 24 GB **discrete** GDDR6X | **128 GB unified** LPDDR5X (~120 GB usable) |
| Mem bandwidth | 936 GB/s | ~273 GB/s |
| Max model (Q4) | ~32B | **~120B** |
| Ollama runtime | **Docker** container | **Native** (systemd) |
| Ollama port | 11434 | 11500 |
| Model store | `/mnt/llm-models/ollama` | `/opt/models` |
| Extra storage | 4 TB + 1 TB NVMe split | single 3.6 TB NVMe at `/` |
| OS / driver / CUDA | Ubuntu 24.04 · 570-open · 12.8 | Ubuntu 24.04 · 580 · 13.0 |
| Image gen (Forge) | ✅ yes (shares the 24 GB card) | ❌ not supported (too slow) |
| Command style | `docker exec -it ollama ollama …` | `ollama …` |

## How to read the two guides

The **big mental switch** between machines is capacity vs. bandwidth, and Docker vs. native:

- **T5820** — capacity-limited (24 GB). You choose models that *fit*; a 32B Q4 is the ceiling.
  High bandwidth means good tokens/sec for models that fit. Ollama lives in Docker, so every
  command is prefixed with `docker exec -it ollama`.

- **GX10** — capacity is enormous (~120 GB), so 70B–120B models load fully. The new limit is
  **memory bandwidth** — token generation is slower per GB than the 3090, and MoE models (few
  active params) win. Ollama is a native systemd service, so you call `ollama …` directly.

When following a guide written for the other machine, translate commands accordingly:

| T5820 (Docker) | GX10 (native) |
|---|---|
| `docker exec -it ollama ollama run X` | `ollama run X` |
| `docker exec -it ollama ollama pull X` | `ollama pull X` |
| `./scripts/start-ollama.sh` | `sudo systemctl start ollama` |
| `docker logs -f ollama` | `journalctl -u ollama -f` |
| port `11434` | port `11500` |

## Shared, machine-independent docs

These apply to both machines (the **benchmark numbers were measured on the T5820's RTX 3090**):

- [Model Selection Guide](shared/Model_Guide.md)
- [Models & Benchmarks](shared/Models_and_Benchmarks.md)
- [Benchmark Automation](shared/Benchmark_Automation.md)

For a **head-to-head GX10 vs. RTX 3090** comparison on the models both machines run — measured
with the native `scripts/benchmark-native.sh` — see
[machines/gx10/Benchmarks.md](machines/gx10/Benchmarks.md).

## Notes

- **Image generation** (Stable Diffusion WebUI Forge) is a **T5820-only** feature by design.
  Diffusion is heavily memory-bandwidth bound, and the GX10's ~273 GB/s unified memory makes it
  impractically slow compared to the RTX 3090's 936 GB/s. The GX10 is for **large-model LLM
  inference**, not image generation.
- The top-level [`setup.sh`](../setup.sh) auto-detects which machine you're on (ARM+native vs.
  x86+Docker) and runs the appropriate verification/bootstrap.
