# Stable Diffusion on RTX 3090 (WebUI Forge)

Image generation alongside the existing Ollama LLM stack, on the same single RTX 3090.

**Engine:** [Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge)
**Port:** 7860 (Ollama stays on 11434)

---

## Quick Start

```bash
cd llm-docker
./scripts/start-forge.sh
```

First run takes **5-10 minutes** (builds the image and installs PyTorch into a persistent
volume). Subsequent starts are fast.

| Endpoint | URL |
|----------|-----|
| Web UI | http://localhost:7860 |
| API docs | http://localhost:7860/docs |

```bash
# Logs
docker compose -f docker-compose.forge.yml logs -f

# Stop
docker compose -f docker-compose.forge.yml down
```

---

## Do Ollama and Forge Conflict?

**No.** They coexist without any special configuration:

- **Separate ports** — Ollama 11434, Forge 7860.
- **Separate containers**, both on the shared `llm-network`.
- **Shared GPU.** Multiple CUDA processes can hold VRAM on one card simultaneously.
  Each allocates independently from the 24 GB pool.

The only real constraint is **total VRAM**. There is no driver-level conflict — you just
can't exceed 24 GB combined.

### VRAM Budgeting

| Workload | VRAM |
|----------|------|
| SDXL | ~8 GB |
| FLUX.1 schnell (fp8) | ~17 GB |
| SD 1.5 | ~4 GB |
| Ollama 7-8B model (Q4) | ~5 GB |
| Ollama 14B model (Q4) | ~9 GB |
| Ollama 32B model (Q4) | ~19 GB |

**Rules of thumb:**

- SDXL + a small/medium LLM → comfortable.
- FLUX + anything large → **will OOM**. Free the LLM first.
- Ollama **auto-unloads idle models after 5 minutes**, so conflicts often resolve themselves.

Force-unload an LLM before a heavy image run:

```bash
docker exec ollama ollama stop <model>
nvidia-smi                      # confirm VRAM freed
```

---

## Checkpoints

Forge is only the **server/UI** — it ships with no weights. A *checkpoint* is the trained
model (a `.safetensors` file) that actually generates images. This is the same relationship
as Ollama (server) vs. `ollama pull llama3.1:8b` (model).

The container launches with `--no-download-sd-model`, so nothing is fetched automatically.

### Installed

| Checkpoint | Size | License | Notes |
|-----------|------|---------|-------|
| `sd_xl_base_1.0` | 6.9 GB | OpenRAIL++-M | Broad style range, huge LoRA ecosystem |
| `flux1-schnell-fp8` | 17.2 GB | **Apache 2.0** | Best prompt-following; 4-step distilled |

> **Licensing:** FLUX.1 schnell is Apache 2.0 — no restrictions on selling generated output
> or derived works. SDXL's OpenRAIL++-M also permits commercial use but carries use-based
> restrictions. For commercial products, FLUX schnell is the cleaner chain.

### Adding a Checkpoint

Drop any `.safetensors` file into the checkpoints directory, then click the **🔄 refresh**
button next to the checkpoint dropdown in the UI (no restart needed):

```bash
cd /mnt/llm-models/stable-diffusion/models/Stable-diffusion/
wget -O my-model.safetensors "<huggingface-or-civitai-url>"
```

Verify a download isn't truncated before loading it — a partial `.safetensors` will throw a
corrupt-tensor error:

```bash
python3 - <<'EOF'
import struct, json, os
f = 'my-model.safetensors'
with open(f,'rb') as fh:
    n = struct.unpack('<Q', fh.read(8))[0]
    hdr = json.loads(fh.read(n))
end = max(v['data_offsets'][1] for k,v in hdr.items() if k != '__metadata__')
print('COMPLETE:', end == os.path.getsize(f) - 8 - n)
EOF
```

---

## Generation Settings

SDXL and FLUX need **different** settings. Reusing SDXL's settings for FLUX produces garbage.

### SDXL

| Setting | Value |
|---------|-------|
| Resolution | 1024×1024 (native — quality collapses below this) |
| Sampler | DPM++ 2M Karras |
| Steps | 25-30 |
| CFG | 6-7 |

### FLUX.1 schnell

| Setting | Value |
|---------|-------|
| Resolution | 1024×1024 |
| Sampler | Euler + Simple scheduler |
| Steps | **4** (distilled — more steps makes output *worse*) |
| CFG / Distilled CFG | 1.0 |

---

## Directory Layout

Models live on the 4TB NVMe alongside the LLM models:

```
/mnt/llm-models/stable-diffusion/
├── models/
│   ├── Stable-diffusion/   # Checkpoints (.safetensors)
│   ├── VAE/                # VAEs
│   ├── Lora/               # LoRAs
│   ├── ControlNet/         # ControlNet models
│   └── ESRGAN/             # Upscalers
├── outputs/                # Generated images
└── embeddings/             # Textual inversion embeddings
```

The Python venv and extensions live in Docker **named volumes** (`forge-venv`,
`forge-extensions`) so PyTorch isn't reinstalled on every container rebuild.

---

## Configuration

Set in `llm-docker/.env`:

```bash
FORGE_PORT=7860
FORGE_ARGS=              # extra launch flags, appended to launch.py
```

Useful `FORGE_ARGS` values:

| Flag | Effect |
|------|--------|
| `--medvram` | Reduce VRAM use (slower) — helps when sharing GPU with a large LLM |
| `--lowvram` | Aggressive VRAM reduction (much slower) |
| `--share` | Public Gradio link |

---

## Build Notes / Gotchas

The Dockerfile and entrypoint work around several issues specific to Ubuntu 24.04 +
Python 3.12. If you modify them, keep these in mind:

| Issue | Fix (already applied) |
|-------|----------------------|
| `libgl1-mesa-glx` has no install candidate | Ubuntu 24.04 obsoleted it — use `libgl1 libglx-mesa0` |
| `/app/venv/bin/activate: not found` | The volume mount pre-creates `/app/venv` as an empty dir. Check for the `activate` **file**, not the directory |
| `rm: cannot remove '/app/venv': Device or resource busy` | Can't `rm` a mount point — clear its *contents* instead |
| CLIP: `No module named 'pkg_resources'` | pip build isolation on Py3.12 — install CLIP with `--no-build-isolation` |
| `cc not found` building open_clip | Needs `build-essential gcc g++` |
| Pillow: `headers for jpeg not found` | Needs `libjpeg-dev libpng-dev libtiff-dev libwebp-dev zlib1g-dev libfreetype-dev` |
| `np.float_ was removed in NumPy 2.0` | Pin `numpy<2` and `scikit-image>=0.22` |

Note the container runs as **root** (standard for SD containers) — running as a non-root
user breaks venv creation inside the mounted volume.

---

## API Usage

Forge exposes the standard A1111 API (`--api` is enabled by default):

```bash
# List available checkpoints
curl -s http://localhost:7860/sdapi/v1/sd-models | python3 -m json.tool

# Re-scan the checkpoints directory after adding a file
curl -X POST http://localhost:7860/sdapi/v1/refresh-checkpoints

# Generate an image (base64 PNG in .images[0])
curl -s -X POST http://localhost:7860/sdapi/v1/txt2img \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"a red ceramic teapot, solid white background, centered, studio lighting",
       "steps":25, "width":1024, "height":1024, "cfg_scale":7}' \
  | python3 -c "import json,sys,base64; open('out.png','wb').write(base64.b64decode(json.load(sys.stdin)['images'][0]))"
```

Full interactive API docs: http://localhost:7860/docs

---

## Related

- [Model Guide](Model_Guide.md) — LLM selection
- [Models & Benchmarks](Models_and_Benchmarks.md) — LLM benchmark data
- [LLM Inference Setup](LLM_Inference_Setup.md) — Ollama/Docker configuration
