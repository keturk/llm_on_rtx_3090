# Asus Ascent GX10 — Hardware Configuration

## System Overview

**Model:** ASUS Ascent GX10 (NVIDIA GB10 Grace Blackwell — DGX Spark class)
**Processor:** 20-core NVIDIA Grace ARM (Cortex-X925 + Cortex-A725)
**Purpose:** Compact desktop AI supercomputer for local LLM inference — large models via **unified memory**

> **The headline difference vs. the [Dell T5820 / RTX 3090](../t5820/Hardware.md):** there is no
> separate 24 GB of VRAM. The GB10's CPU and GPU share **one 128 GB coherent LPDDR5X pool**, so
> the GPU can address ~120 GB of model weights. This box runs **70B–120B** models the 3090
> physically cannot hold — but at lower memory bandwidth, so tokens/sec is the trade-off, not
> capacity.

---

## Detailed Specifications

### CPU
- **Model:** NVIDIA Grace (ARM `aarch64`)
- **Cores:** 20 (10× Cortex-X925 performance + 10× Cortex-A725 efficiency)
- **Max Clock:** 3.9 GHz
- **ISA extensions:** NEON, SVE/SVE2, FP16, BF16, I8MM, dotprod, SHA3/SM4
- **Note:** ARM, **not** x86 — some Docker images and prebuilt binaries are x86-only and won't
  run here. Ollama ships native `arm64` builds.

### Memory (Unified)
- **Total:** 128 GB LPDDR5X, **coherent / unified** between CPU and GPU
- **Usable by GPU (CUDA):** ~124 GB visible, ~121 GB free for models
- **Bandwidth:** ~273 GB/s (vs. 936 GB/s on the RTX 3090's dedicated GDDR6X)
- **Implication:** capacity is huge, bandwidth is the bottleneck. Token generation is
  memory-bandwidth bound, so a model that *fits* here may still generate slower than the same
  model on a 3090 — but models far larger than 24 GB become possible at all.

### Storage
| Drive | Capacity | Type | Mount Point | Purpose |
|-------|----------|------|-------------|---------|
| System + data | 3.6 TB | NVMe SSD | `/` | OS, models, everything |

- **No separate model/data drives** (unlike the T5820's `/mnt/llm-models` + `/mnt/llm-data`).
- **Ollama model store:** `/opt/models` (set via `OLLAMA_MODELS`, see [Setup.md](Setup.md)).

### Graphics
- **Model:** NVIDIA GB10 (Blackwell architecture)
- **Compute Capability:** 12.1 (`sm_121`) — supports **native FP4** (`BLACKWELL_NATIVE_FP4=1`)
- **Memory:** shared unified pool (see above); `nvidia-smi` reports memory as *"Not Supported"*
  because it is not a discrete VRAM partition — this is expected on GB10.
- **CUDA archs in the Ollama build:** 750, 800, 860, 890, 900, 1000, 1030, 1100, 1200, 1210

### Operating System
- **Distribution:** Ubuntu 24.04.4 LTS (`aarch64`)
- **Kernel:** Linux 6.17 (`nvidia` flavor)
- **NVIDIA Driver:** 580.159.03
- **CUDA Version:** 13.0

---

## LLM Inference Capabilities

### Maximum Model Sizes
Capacity is governed by the **unified memory pool (~120 GB usable)**, not a 24 GB VRAM wall:

- **Comfortable:** up to ~70B dense (Q4) or large MoE models
- **Maximum:** ~120B-class models (e.g. `nemotron-3-super:120b`, ~86 GB) load **fully on GPU**
- **Sweet spot:** MoE models (few active params) run fastest for their size, since bandwidth —
  not capacity — is the limit here

### Verified On This Machine
- `nemotron-3-super:120b` (86 GB) — **89/89 layers offloaded to GPU**, runs entirely in unified
  memory
- `nemotron-3-nano:30b` (24 GB)

> Throughput (tokens/sec) is measured natively with [`scripts/benchmark-native.sh`](../../../scripts/benchmark-native.sh)
> and recorded — with a head-to-head RTX 3090 comparison — in **[Benchmarks.md](Benchmarks.md)**.
> Do not assume the RTX 3090 numbers in
> [shared/Models_and_Benchmarks.md](../../shared/Models_and_Benchmarks.md) apply here; they are
> bandwidth-bound and differ.

### Storage Capacity
- ~3.3 TB free on `/` — plenty for a large library of big models (a 120B model is ~50–90 GB).

---

## Power & Thermal Considerations

- Compact, low-power desktop form factor (no 350W discrete GPU).
- Whole-system draw is a fraction of the T5820 under load.
- Passively/actively cooled as a sealed appliance — no user GPU-fan tuning as on the T5820.

---

## Key Differences vs. Dell T5820 / RTX 3090

| | Dell T5820 | ASUS GX10 (this machine) |
|---|---|---|
| CPU ISA | x86-64 (Intel Xeon) | **ARM aarch64** (Grace) |
| GPU | RTX 3090, 24 GB **discrete** GDDR6X | GB10 Blackwell, **unified** memory |
| Model memory | 24 GB VRAM | **~120 GB** unified pool |
| Mem bandwidth | 936 GB/s | ~273 GB/s |
| Max model | ~32B (Q4) | **~120B** |
| Ollama runtime | **Docker** container | **Native** (systemd) |
| Ollama port | 11434 | **11500** |
| Model store | `/mnt/llm-models/ollama` | `/opt/models` |
| CUDA | 12.8 | 13.0 |

See [Setup.md](Setup.md) for the native-Ollama configuration on this machine.

---

## Notes

- This is an appliance-class system: the OS, driver, CUDA, and Ollama came preconfigured.
- Unified memory means "loading a model into VRAM" and "loading into RAM" are the same act —
  there is no PCIe copy between host and device, which helps latency for huge models.
- Because the GPU is `sm_121` (very new), prefer **native ARM builds** and recent CUDA 13
  toolchains; older containers built for `sm_86` (Ampere) may lack optimized kernels.
