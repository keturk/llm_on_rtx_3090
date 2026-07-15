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
GX10 [3b–14b](../../../benchmark_results/gx10_benchmark_20260715_000327.md) ·
[14b](../../../benchmark_results/gx10_benchmark_20260715_002100.md) ·
[27b–34b](../../../benchmark_results/gx10_benchmark_20260715_002133.md),
T5820 [all](../../../benchmark_results/t5820_benchmark_20260714_234234.md).

| Model | Size | GX10 tok/s | RTX 3090 tok/s | RTX 3090 is |
|-------|------|-----------:|---------------:|:-----------:|
| llama3.2:3b | 2.0 GB | 57.3 | 196.1 | 3.4× faster |
| llama3.1:8b | 4.9 GB | 28.2 | 121.1 | 4.3× |
| mistral:7b | 4.4 GB | 31.1 | 145.8 | 4.7× |
| qwen2.5:7b | 4.7 GB | 29.8 | 122.1 | 4.1× |
| phi3:14b | 7.9 GB | 19.2 | 91.8 | 4.8× |
| qwen2.5:14b | 9.0 GB | 13.8 | 70.7 | 5.1× |
| gemma2:27b | 15 GB | 8.5 | 43.3 | 5.1× |
| qwen2.5:32b | 19 GB | 7.0 | 8.3 ⚠️ | (see note) |
| codellama:34b | 19 GB | 7.8 | 41.8 | 5.4× |
| deepseek-coder:33b | 18 GB | 7.8 | 40.9 | 5.2× |

The RTX 3090 is **3.4–5.4× faster on every model that fits its 24 GB** — and the lead *widens*
with size rather than narrowing. The floor is the memory-bandwidth ratio (936 ÷ 273 ≈ 3.4×,
which bounds token generation); on larger dense models the 3090's newer compute stretches it
further. **The GX10's advantage is capacity, not speed** — see the big-model table below for the
models this flips on.

> ⚠️ **`qwen2.5:32b` = 8.3 tok/s on the 3090 is a bad sample, not a real result.** Two other
> models of the same footprint — `codellama:34b` (19 GB) and `deepseek-coder:33b` (18 GB) — run
> at ~41 tok/s on the same card, so the 3090 clearly handles this size fine; that one run spilled
> to CPU. Re-run it (its true value is ~40+). It is **not** evidence of a capacity wall — do not
> use it as a "crossover" in the post.

### Big models (GX10-only — will not fit on a 24 GB card)

Measured 2026-07-14 with `./scripts/benchmark-native.sh big` (raw:
[`benchmark_results/gx10_benchmark_20260714_224729.md`](../../../benchmark_results/gx10_benchmark_20260714_224729.md)):

| Model | Size | GX10 tok/s | RTX 3090 | Notes |
|-------|------|-----------:|:--------:|-------|
| nemotron-3-nano:30b | 24 GB | **43.7** | ⚠️ borderline (24 GB) | hybrid (Mamba-Transformer) |
| nemotron-3-super:120b | 86 GB | **13.1** | ❌ won't fit | 120B hybrid, fully in unified memory |

The headline result: a **120B model generates at ~13 tok/s** on this box — usable, and simply
**impossible** on a 24 GB RTX 3090. That is the GX10's reason to exist.

**Architecture matters more than size here.** Look at two ~30B models on the *same* GX10:
`nemotron-3-nano:30b` (hybrid Mamba-Transformer) runs at **43.7 tok/s**, while the dense
`qwen2.5:32b` runs at **7.0 tok/s** — a 6× gap at nearly identical parameter counts. On
bandwidth-bound hardware, models that read fewer parameters per token (hybrid / MoE / SSM) win
enormously. The 120B Nemotron beating dense 32B models (13 vs 7 tok/s) is the same effect. **On
the GX10, pick the architecture, not just the size.**

---

## Related

- [Setup.md](Setup.md) — running these models on the GX10
- [Hardware.md](Hardware.md) — why bandwidth, not capacity, is the limit here
- [../../shared/Models_and_Benchmarks.md](../../shared/Models_and_Benchmarks.md) — full RTX 3090 model catalog
- [../../MACHINES.md](../../MACHINES.md) — machine comparison
