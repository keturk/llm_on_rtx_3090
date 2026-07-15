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
| tok/s source | `ollama --verbose` **`eval rate`** (accurate, excludes load) | same |
| Prompt | "explain supervised vs unsupervised… in 3 sentences" | same |

**Both machines are now measured with the identical accurate method** (`scripts/benchmark.sh`,
which auto-detects Docker vs native). The numbers below are directly comparable. (An earlier
RTX 3090 table used a crude `words × 1.3 ÷ wall-clock` estimate that badly under-reported —
e.g. it put llama3.2:3b at 48 tok/s when the real eval rate is ~196; those old figures are
superseded.)

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

Both columns measured with `scripts/benchmark.sh` (accurate `eval rate`). Raw files:
GX10 [`gx10_benchmark_20260715_000327.md`](../../../benchmark_results/gx10_benchmark_20260715_000327.md),
T5820 [`t5820_benchmark_20260714_234234.md`](../../../benchmark_results/t5820_benchmark_20260714_234234.md).

| Model | Size | GX10 tok/s | RTX 3090 tok/s | RTX 3090 is |
|-------|------|-----------:|---------------:|:-----------:|
| llama3.2:3b | 2.0 GB | 57.3 | 196.1 | 3.4× faster |
| llama3.1:8b | 4.9 GB | 28.2 | 121.1 | 4.3× |
| mistral:7b | 4.4 GB | 31.1 | 145.8 | 4.7× |
| qwen2.5:7b | 4.7 GB | 29.8 | 122.1 | 4.1× |
| phi3:14b | 7.9 GB | 19.2 | 91.8 | 4.8× |
| qwen2.5:14b | 9.0 GB | _pending_ | 70.7 | — |
| gemma2:27b | 15 GB | _pending_ | 43.3 | — |
| qwen2.5:32b | 19 GB | _pending_ | 8.3 ⚠️ | — |
| codellama:34b | 19 GB | _pending_ | 41.8 | — |
| deepseek-coder:33b | 18 GB | _pending_ | 40.9 | — |

The RTX 3090 is **3.4–4.8× faster** on every small/mid model that fits its 24 GB — closely
tracking the memory-bandwidth ratio (936 ÷ 273 ≈ 3.4×), which is what bounds token generation.
The GX10's advantage is capacity, not speed.

> ⚠️ **`qwen2.5:32b` = 8.3 tok/s on the 3090 is an outlier** — slower than the larger 33–34B
> models, which means it partially spilled to CPU near the 24 GB ceiling on that run. Re-run it
> before quoting, or read it as "the 3090 starts hitting its wall around 32B." The GX10 (with
> ~120 GB) has no such ceiling. _(GX10 rows for the 14B–34B tier are still being collected.)_

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
