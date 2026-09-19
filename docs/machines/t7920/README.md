# Dell Precision T7920 (RTX 3090) -- shared host

Same hardware class as the [T5820](../t5820/README.md) -- x86-64, one discrete **24 GB RTX 3090**,
Ollama in Docker -- on a box that is **shared with other projects** and has a different
storage shape. Everything in the T5820 guides applies; this page is only the differences.

| | |
|---|---|
| CPU / RAM | 2x Xeon Silver 4114 (20 cores), 128 GB |
| GPU | NVIDIA RTX 3090, 24 GB (discrete) |
| OS | Ubuntu 24.04 Desktop, driver 595-open (held), Docker CE 29 + Compose v5, NVIDIA container toolkit |
| Host user | whoever runs `setup-t7920.sh` (unit and cron are rendered for that user) |
| Hot model tier | `/srv/llm-models` -- OS NVMe, ~300 GB budget |
| Cold model tier | `/mnt/data/llm-models` -- 8 TB HDD |
| Working data | `/mnt/data/llm-data` -- HDD (logs, benchmarks, tier ledger) |
| Ollama | Docker, port **11434**, `OLLAMA_KEEP_ALIVE=30m` |
| Ports owned by other tenants | `RESERVED_PORTS` in `.env.t7920` (8080 among them) -- TGI moved to **8081** |

## Why two tiers

No spare NVMe for a 4 TB model disk. The HDD holds everything (loads at ~250 MB/s: ~80 s
for a 32B model, once per boot -- the machine is powered off overnight); the NVMe holds the
models that are actually used. `scripts/ollama-tier.sh` decides from measured usage
(Ollama's own load log), not by hand:

- loaded >= 3 times in 14 days -> promoted to NVMe
- unused for 30 days -> demoted to HDD
- `pin <model>` keeps a model on NVMe regardless; the hot tier is capped at 300 GB
- runs weekly under anacron; `list` shows every model's tier, size, loads and last use

Mechanically a cold model is one whose blobs were moved to the HDD and replaced by
symlinks in the store (the HDD path is mounted into the container at the same absolute
path). Manifests never move, so `ollama list`/`run` see every model either way; a new
`ollama pull` lands hot and earns its place.

## Engines on this machine

| Modality | Engine | Compose file | Starts | VRAM when active | Port |
|---|---|---|---|---|---|
| text, vision, embeddings | Ollama | `docker-compose.yml` + `t7920` override | at boot | the loaded model (5-19 GB), `keep_alive` 30m | 11434 |
| speech -> text | whisper-asr-webservice (faster-whisper, `large-v3-turbo`) | `docker-compose.speech.yml` | at boot | ~3 GB after first request | 9200 |
| text -> speech | Kokoro-FastAPI (OpenAI-compatible `/v1/audio/speech`) | `docker-compose.speech.yml` | at boot | ~1 GB | 8880 |
| chat / image / voice UI | Open WebUI (over Ollama, Forge, Kokoro) | `docker-compose.webui.yml` | at boot | none | 8082 |
| image generation | SD WebUI Forge (SDXL, FLUX) | `docker-compose.forge.yml` | **on demand** `scripts/start-forge.sh` | 8 GB SDXL / 17 GB FLUX, offloaded when idle | 7860 |
| OpenAI API, high throughput | vLLM | `docker-compose.vllm.yml` | opt-in `scripts/start-vllm.sh` | claims most of the card -- not alongside the rest | 8000 |

Ollama, Forge and the speech engines are the ones this repo's T5820 guides cover; whisper,
Kokoro and Open WebUI are **derived** additions (images and settings from each project's own
documentation, not yet benchmarked here). vLLM is documented upstream only.

**One card, 24 GB.** Everything that autostarts holds no VRAM until used, and Ollama releases
a model 30 minutes after its last request. What does not fit at the same time is a 32B text
model (19 GB) next to FLUX (17 GB) -- unload one first (`docker exec ollama ollama stop
<model>`) or use SDXL. The budget that always fits: a 14B model + SDXL + whisper + Kokoro.

## Setup

```bash
git clone https://github.com/keturk/llm_on_rtx_3090.git ~/llm_on_rtx_3090
cd ~/llm_on_rtx_3090/llm-docker
./scripts/setup-t7920.sh        # tree, .env, stack up (ollama + speech + web UI), GPU proof, boot unit, tier job, first model
```

Then open Open WebUI and create the first account -- it becomes the administrator -- before
anyone else on the network finds the port.

Files that make this machine: [`llm-docker/.env.t7920`](../../../llm-docker/.env.t7920),
[`docker-compose.t7920.yml`](../../../llm-docker/docker-compose.t7920.yml) (cold-tier mount,
keep-alive), [`systemd/llm-stack.t7920.service`](../../../llm-docker/systemd/llm-stack.t7920.service),
[`scripts/ollama-tier.sh`](../../../llm-docker/scripts/ollama-tier.sh),
[`scripts/setup-t7920.sh`](../../../llm-docker/scripts/setup-t7920.sh),
[`docker-compose.speech.yml`](../../../llm-docker/docker-compose.speech.yml),
[`docker-compose.webui.yml`](../../../llm-docker/docker-compose.webui.yml).

## Shared-host rules

- Nothing here touches ufw, cron.d, `/etc/docker/daemon.json` or the driver: those are
  host-level and other projects depend on them. Docker-published ports bypass ufw, so
  `:11434` is reachable from the whole LAN without authentication -- fine for a trusted
  network, not for anything else.
- The stack is its own Compose project (`llm-docker`, network `llm-network`); it never shares
  a network or a volume with the other stacks on the machine.
- Forge is not started at boot (10 GB of VRAM); `./scripts/start-forge.sh` when needed.
