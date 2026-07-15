# GX10 Benchmarks — and how they compare to the RTX 3090

This page holds throughput numbers for the ASUS GX10 (NVIDIA GB10) and puts them **side-by-side
with the Dell T5820 / RTX 3090** for the models both machines can run.

Why bother comparing small models the GX10 doesn't "need"? Because it answers the practical
question: *for a model that fits on a 24 GB card, do I lose speed by running it on the GX10?*
The GX10's job is the 70B–120B tier — but knowing the crossover helps you decide where to run
everything else.

---

## How to run it

```bash
cd ~/llm_on_rtx_3090

# The comparison set (models with recorded RTX 3090 numbers). Pulls are ~90 GB total.
./scripts/benchmark-native.sh compare --pull

# Just the big, GX10-only models (already installed on this machine)
./scripts/benchmark-native.sh big

# Everything
./scripts/benchmark-native.sh all --pull -y
```

Results are written to `benchmark_results/gx10_benchmark_<timestamp>.md` (tracked in git). Paste
the resulting table into the [Results](#results) section below.

---

## Methodology — read this before comparing numbers

The two machines were **not** measured identically, so compare with care:

| | RTX 3090 (T5820) | GX10 |
|---|---|---|
| Script | `llm-docker/scripts/comprehensive-benchmark.sh` | `scripts/benchmark-native.sh` |
| Runtime | Ollama in Docker | native Ollama |
| tok/s source | `words × 1.3 ÷ wall-clock` (**estimate**, includes model load) | `ollama --verbose` **`eval rate`** (**accurate**, excludes load) |
| Prompt | "explain supervised vs unsupervised… in 3 sentences" | same |

The GX10 method is strictly more accurate. The 3090's estimate tends to **under**-report (wall
clock includes load time and token counts are approximate). So a small GX10 advantage may be
partly methodology, not hardware — treat differences under ~15% as noise. For a truly clean
comparison, re-run the 3090 with `--verbose` parsing too (a future improvement to the Docker
script).

### What to expect on the GX10

- **Memory-bandwidth bound.** GB10 unified memory ≈ **273 GB/s** vs the RTX 3090's **936 GB/s**.
  Token generation scales with bandwidth, so for a model that fits on both, the 3090 is often
  **faster**. The GX10 wins on *capacity*, not raw small-model speed.
- **MoE models punch above their size** — only active params are read per token, so a 30B-A3B or
  a 120B MoE runs far quicker than its total size suggests.
- **Load times are long** (tens of seconds for big models) — which is exactly why `eval rate`
  (load excluded) is the honest metric, and why `OLLAMA_KEEP_ALIVE=-1` keeps models resident.

---

## Results

### Comparison set (fits on RTX 3090)

> Run `./scripts/benchmark-native.sh compare --pull` and paste the generated table here.
> The RTX 3090 column is pre-filled from the T5820 reference run.

| Model | Size | GX10 tok/s | RTX 3090 tok/s | Fits 3090? |
|-------|------|-----------:|---------------:|:----------:|
| llama3.2:3b | ~3 GB | _TBD_ | 48.3 | ✅ |
| llama3.1:8b | ~6 GB | _TBD_ | 47.1 | ✅ |
| mistral:7b | ~5 GB | _TBD_ | 65.3 | ✅ |
| qwen2.5:7b | ~5 GB | _TBD_ | 30.5 | ✅ |
| phi3:14b | ~9 GB | _TBD_ | 31.7 | ✅ |
| qwen2.5:14b | ~10 GB | _TBD_ | 25.1 | ✅ |
| gemma2:27b | ~17 GB | _TBD_ | 20.8 | ✅ |
| qwen2.5:32b | ~20 GB | _TBD_ | 20.2 | ✅ |
| codellama:34b | ~20 GB | _TBD_ | 22.4 | ✅ |
| deepseek-coder:33b | ~20 GB | _TBD_ | 19.9 | ✅ |

### Big models (GX10-only — will not fit on a 24 GB card)

Measured 2026-07-14 with `./scripts/benchmark-native.sh big` (raw:
[`benchmark_results/gx10_benchmark_20260714_224729.md`](../../../benchmark_results/gx10_benchmark_20260714_224729.md)):

| Model | Size | GX10 tok/s | RTX 3090 | Notes |
|-------|------|-----------:|:--------:|-------|
| nemotron-3-nano:30b | 24 GB | **43.7** | ⚠️ borderline (24 GB) | dense 30B |
| nemotron-3-super:120b | 86 GB | **13.1** | ❌ won't fit | 120B — fully in unified memory, still usable |

The headline result: a **120B model generates at ~13 tok/s** on this box — slower than a small
model, but perfectly usable, and simply **impossible** on a 24 GB RTX 3090. That is the GX10's
reason to exist. The 30B lands at ~44 tok/s, so the capacity ceiling (not speed) is what scales
across this range.

---

## Related

- [Setup.md](Setup.md) — running these models on the GX10
- [Hardware.md](Hardware.md) — why bandwidth, not capacity, is the limit here
- [../../shared/Models_and_Benchmarks.md](../../shared/Models_and_Benchmarks.md) — full RTX 3090 model catalog
- [../../MACHINES.md](../../MACHINES.md) — machine comparison
