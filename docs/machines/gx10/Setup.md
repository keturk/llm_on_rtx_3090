# GX10 Inference Setup — Native Ollama on ARM

**System:** ASUS Ascent GX10 (NVIDIA GB10 Grace Blackwell, `aarch64`)
**OS:** Ubuntu 24.04.4 LTS · Driver 580.159.03 · CUDA 13.0
**Goal:** Run LLM inference with **native Ollama** (systemd), using the 128 GB unified memory
pool to serve models far larger than a discrete GPU could hold.

> **This machine does not use Docker for LLMs.** On the [Dell T5820](../t5820/Inference_Setup.md),
> Ollama runs in a Docker container and every command is `docker exec -it ollama ollama …`.
> Here, Ollama is a **native systemd service** and you call `ollama …` directly. Drop the
> `docker exec -it ollama` prefix from every command you see in the T5820 docs.

---

## Table of Contents
1. [What's Already Configured](#whats-already-configured)
2. [The systemd Service](#the-systemd-service)
3. [Talking to Ollama](#talking-to-ollama)
4. [Verifying GPU / Unified Memory](#verifying-gpu--unified-memory)
5. [Model Management](#model-management)
6. [Running Big Models](#running-big-models)
7. [Changing Configuration](#changing-configuration)
8. [Quick Reference](#quick-reference)
9. [Troubleshooting](#troubleshooting)

---

## What's Already Configured

The GX10 ships as an AI appliance — the OS, NVIDIA driver, CUDA 13, and a **native ARM Ollama
build** come preinstalled. There is no driver install, no NVMe formatting, and no Docker/NVIDIA
Container Toolkit step (all of which the T5820 requires). Run `./setup.sh` from the repo root to
**verify** the environment rather than build it:

```bash
cd ~/llm_on_rtx_3090
./setup.sh          # detects ARM + native Ollama, verifies GPU and service
```

Quick manual checks:

```bash
uname -m                       # aarch64
ollama --version               # 0.30.x
systemctl is-active ollama     # active
nvidia-smi                     # NVIDIA GB10, driver 580, CUDA 13
```

---

## The systemd Service

Ollama runs as `ollama.service`. The base unit lives at `/etc/systemd/system/ollama.service`
and machine-specific settings are in a drop-in override:

```ini
# /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_MODELS=/opt/models"
Environment="OLLAMA_HOST=127.0.0.1:11500"
Environment="OLLAMA_KEEP_ALIVE=-1"
```

| Setting | Value | Why |
|---------|-------|-----|
| `OLLAMA_MODELS` | `/opt/models` | Model blobs on the 3.6 TB system NVMe (no `/mnt/llm-models` split here) |
| `OLLAMA_HOST` | `127.0.0.1:11500` | Server bind address/port — **note: 11500, not the default 11434** |
| `OLLAMA_KEEP_ALIVE` | `-1` | Keep models resident indefinitely. Cheap here — unified memory is large, and reloading an 86 GB model is slow, so pinning it pays off |

> **Note:** port **11434** on this box also answers (a lightweight proxy forwards to the native
> server), so the stock `ollama` CLI and OpenAI-compatible clients work with no extra config. To
> address the native server directly, use `http://127.0.0.1:11500`.

---

## Talking to Ollama

The standard CLI works out of the box — no `docker exec`, no host flag:

```bash
ollama list
ollama run nemotron-3-nano:30b "Explain unified memory in one paragraph"
```

To target the native server explicitly (e.g. from scripts or another host on the network):

```bash
export OLLAMA_HOST=127.0.0.1:11500
curl http://127.0.0.1:11500/api/tags
curl http://127.0.0.1:11500/api/generate -d '{"model":"nemotron-3-nano:30b","prompt":"Hello!"}'
```

Add the `export` line to `~/.bashrc` if you want every shell to hit 11500 directly.

---

## Verifying GPU / Unified Memory

Confirm Ollama is using the GB10 and how much memory it sees:

```bash
journalctl -u ollama --no-pager | grep -iE "gpu memory|CUDA0|offloaded|BLACKWELL" | tail
```

Healthy output looks like:

```
gpu memory id=0 library=CUDA available="118.2 GiB" free="118.7 GiB"
  - CUDA0 : NVIDIA GB10 (124609 MiB, 121443 MiB free)
system_info: ... CUDA : ARCHS = 750,800,...,1200,1210 | BLACKWELL_NATIVE_FP4 = 1 |
load_tensors: offloaded 89/89 layers to GPU
```

Key things to see:
- **`NVIDIA GB10 (124609 MiB … free)`** — the GPU addresses ~124 GB of the unified pool.
- **`offloaded N/N layers to GPU`** — the *whole* model is on the GPU. Even the 120B model shows
  `89/89`. If you ever see `offloaded X/N` with `X < N`, part is spilling to CPU-side execution.
- `nvidia-smi` reports GPU memory as **"Not Supported"** — expected on GB10 (unified memory is not
  a discrete VRAM partition). Trust the Ollama logs, not `nvidia-smi`, for memory accounting.

---

## Model Management

Models live in `/opt/models`:

```bash
ollama list                    # installed models
du -sh /opt/models             # total on-disk size
ollama pull qwen3:14b          # download a model
ollama rm <model>              # remove a model
ollama ps                      # what's currently loaded in memory
```

Already installed on this machine:

```
nemotron-3-super:120b    86 GB
nemotron-3-nano:30b      24 GB
```

---

## Running Big Models

This is the reason for the machine — models that never fit on a 24 GB card:

```bash
# 120B-class model, fully resident in unified memory (~86 GB)
ollama run nemotron-3-super:120b "Design a fault-tolerant task queue and justify the trade-offs"

# 30B for faster iteration
ollama run nemotron-3-nano:30b "Refactor this function for readability"
```

**Bandwidth, not capacity, is the limit here.** A model that fits comfortably may still generate
tokens slower than a small model on the T5820's 3090, because generation speed scales with
memory bandwidth (~273 GB/s) and the number of *active* parameters per token. MoE models (few
active params) give the best tokens/sec for their size.

> Benchmark this machine — and compare it head-to-head with the RTX 3090 on models that fit both
> — with the native suite:
> ```bash
> ./scripts/benchmark-native.sh compare --pull    # 3090-class models
> ./scripts/benchmark-native.sh big               # 30B/120B, GX10-only
> ```
> Results and methodology live in **[Benchmarks.md](Benchmarks.md)**. The RTX 3090 figures in
> [shared/Models_and_Benchmarks.md](../../shared/Models_and_Benchmarks.md) are **not** directly
> transferable — the GX10 is bandwidth-bound.

---

## Changing Configuration

To change the port, model directory, or keep-alive, edit the drop-in override and reload:

```bash
sudo systemctl edit ollama            # opens the override.conf
# ...edit Environment= lines...

sudo systemctl daemon-reload
sudo systemctl restart ollama
systemctl show ollama -p Environment  # confirm new values
```

To move the model store to a different path, set `OLLAMA_MODELS`, create the directory owned by
the `ollama` user, and restart:

```bash
sudo mkdir -p /new/path && sudo chown -R ollama:ollama /new/path
# set OLLAMA_MODELS=/new/path in the override, then daemon-reload + restart
```

---

## Quick Reference

```bash
# Service control
sudo systemctl restart ollama
sudo systemctl stop ollama
systemctl status ollama
journalctl -u ollama -f                # live logs

# Models (no docker exec!)
ollama list
ollama pull <model>
ollama run <model> "prompt"
ollama ps                              # loaded models
ollama stop <model>                    # unload one model

# API
curl http://127.0.0.1:11500/api/tags
curl http://127.0.0.1:11500/api/version

# Health
nvidia-smi
systemctl is-active ollama
```

---

## Troubleshooting

### `ollama` command talks to the wrong server
The CLI defaults to `127.0.0.1:11434`. If that proxy is down but the native server is up, point
the client at the real port:
```bash
export OLLAMA_HOST=127.0.0.1:11500
```

### Model runs slowly / partially on CPU
```bash
journalctl -u ollama --no-pager | grep -i "offloaded"
# Want: offloaded N/N layers to GPU  (all layers)
```
If fewer than N layers offloaded, the model plus its KV cache exceeded the free unified pool.
Free memory (`ollama stop <other-model>`) or reduce context size.

### Service won't start after editing the override
```bash
sudo systemctl daemon-reload
journalctl -u ollama --no-pager | tail -30    # look for a bad Environment= line
```

### `nvidia-smi` shows memory "Not Supported"
Expected on GB10 — unified memory isn't a discrete VRAM partition. Use the Ollama logs
(`CUDA0 : NVIDIA GB10 (… free)`) to see available memory instead.

### An x86-only tool won't run
This is an `aarch64` machine. Prefer native ARM builds. Docker images built only for
`linux/amd64` will fail or run under slow emulation — Ollama itself is native ARM, so you rarely
need Docker here.

---

**System:** ASUS GX10 + NVIDIA GB10 · **Runtime:** Native Ollama (systemd) · **Port:** 11500
**Prerequisite:** none (appliance ships configured) · **Status:** Working ✓
