# GX10 Benchmarks — and how they compare to the RTX 3090

This page holds throughput numbers for the ASUS GX10 (NVIDIA GB10) and puts them **side-by-side
with the Dell T5820 / RTX 3090** for the models both machines can run.

Why bother comparing small models the GX10 doesn't "need"? Because it answers the practical
question: *for a model that fits on a 24 GB card, do I lose speed by running it on the GX10?*
The GX10's job is the 70B–120B tier — but knowing the crossover helps you decide where to run
everything else.

---

## How to run it

`scripts/benchmark.sh` auto-detects the runtime (native on the GX10, Docker on the T5820), so the
same command measures either machine identically:

```bash
cd ~/llm_on_rtx_3090

# The comparison set (models with recorded RTX 3090 numbers)
./scripts/benchmark.sh compare --pull -y

# Just the big, GX10-only models (30B / 120B)
./scripts/benchmark.sh big

# The complete 49-model suite (pulls each model on demand, benchmarks as it goes)
./scripts/benchmark.sh full --pull -y
```

Results are written to `benchmark_results/<machine>_benchmark_<timestamp>.md` (tracked in git).

---

## Methodology

Both machines are measured with the **identical** method — same script, same metric, same prompt:

| | RTX 3090 (T5820) | GX10 |
|---|---|---|
| Script | `scripts/benchmark.sh` (auto-detects) | same |
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

## Full suite — all 49 models on the GX10

The GX10 now mirrors the RTX 3090's model library. Complete native run:
[`gx10_benchmark_20260716_002828.md`](../../../benchmark_results/gx10_benchmark_20260716_002828.md).
Across the whole suite the dominant variable is **not size — it's architecture.**

### Same size, opposite result

Group models by parameter count and the split is stark: every **dense** model of a given size
lands in the same narrow band, while **MoE / hybrid** models of the *same* size run multiples
faster (fewer parameters read per token → less memory traffic on a ~273 GB/s bus).

| Size | Dense (tok/s) | MoE / hybrid (tok/s) | Gap |
|------|--------------|----------------------|-----|
| ~3B | llama3.2:3b **50.6** · ministral-3:3b 52.9 | granite3.1-moe:3b **115.1** | ~2.2× |
| ~30–32B | qwen2.5:32b **7.0** · deepseek-r1:32b 6.9 · qwq:32b 6.9 | qwen3:30b-a3b **53.5** · qwen3-coder:30b 50.8 · nemotron-3-nano:30b 47.1 | **~7.6×** |
| 120B | _(nothing dense this size runs here)_ | nemotron-3-super:120b **13.2** | > any dense 32B |

The kicker: **a 120B hybrid MoE (13 tok/s) is nearly 2× faster than any dense 32B model (~7 tok/s).**
`granite3.1-moe:3b` tops the entire 49-model suite at **115 tok/s**.

### Every dense model is bandwidth-bound

Dense throughput falls off a cliff with size and clusters tightly at each tier — because
generation reads *all* parameters every token:

| Dense size tier | tok/s range |
|-----------------|-------------|
| 1.7–4B | 41–72 |
| 7–9B | 25–32 |
| 12–14B | 15–17 |
| 22–27B | 8–11 |
| 32–34B | **6.8–7.9** (six models, all within 1 tok/s) |

<details>
<summary><b>Full ranking — all 49 models, fastest first</b></summary>

| # | Model | Size | Arch | GX10 tok/s |
|--:|-------|------|------|-----------:|
| 1 | granite3.1-moe:3b | 2.0 GB | MoE | 115.1 |
| 2 | smollm2:1.7b | 1.8 GB | dense | 72.2 |
| 3 | phi3.5 | 2.2 GB | dense | 58.7 |
| 4 | qwen3:30b-a3b | 18 GB | MoE | 53.5 |
| 5 | ministral-3:3b | 3.0 GB | dense | 52.9 |
| 6 | qwen3-coder:30b | 18 GB | MoE | 50.8 |
| 7 | llama3.2:3b | 2.0 GB | dense | 50.6 |
| 8 | nemotron-mini:4b | 2.7 GB | dense | 47.3 |
| 9 | nemotron-3-nano:30b | 24 GB | hybrid | 47.1 |
| 10 | phi4-mini | 2.5 GB | dense | 47.1 |
| 11 | gemma3:4b | 3.3 GB | dense | 41.6 |
| 12 | hermes3:8b | 4.7 GB | dense | 32.0 |
| 13 | mistral:7b | 4.4 GB | dense | 30.6 |
| 14 | falcon3:7b | 4.6 GB | dense | 30.0 |
| 15 | marco-o1:7b | 4.7 GB | dense | 29.6 |
| 16 | exaone-deep:7.8b | 4.8 GB | dense | 29.4 |
| 17 | qwen2.5:7b | 4.7 GB | dense | 29.3 |
| 18 | dolphin3 | 4.9 GB | dense | 28.4 |
| 19 | llama3.1:8b | 4.9 GB | dense | 27.8 |
| 20 | glm4:9b | 5.5 GB | dense | 27.7 |
| 21 | qwen3:8b | 5.2 GB | dense | 27.5 |
| 22 | qwen3-vl:8b | 6.1 GB | dense | 27.0 |
| 23 | deepseek-r1:8b | 5.2 GB | dense | 26.7 |
| 24 | granite3-dense:8b | 4.9 GB | dense | 26.5 |
| 25 | ministral-3:8b | 6.0 GB | dense | 25.8 |
| 26 | aya-expanse:8b | 5.1 GB | dense | 25.3 |
| 27 | falcon3:10b | 6.3 GB | dense | 21.7 |
| 28 | phi3:14b | 7.9 GB | dense | 17.5 |
| 29 | gemma3:12b | 8.1 GB | dense | 17.4 |
| 30 | ministral-3:14b | 9.1 GB | dense | 16.6 |
| 31 | olmo2:13b | 8.4 GB | dense | 16.3 |
| 32 | deepseek-r1:14b | 9.0 GB | dense | 15.5 |
| 33 | qwen3:14b | 9.3 GB | dense | 15.4 |
| 34 | qwen2.5:14b | 9.0 GB | dense | 15.3 |
| 35 | phi4 | 9.1 GB | dense | 15.3 |
| 36 | qwen2.5-coder:14b | 9.0 GB | dense | 14.9 |
| 37 | nemotron-3-super:120b | 86 GB | hybrid | 13.2 |
| 38 | codestral:22b | 12 GB | dense | 11.4 |
| 39 | mistral-small:24b | 14 GB | dense | 9.4 |
| 40 | gemma2:27b | 15 GB | dense | 9.2 |
| 41 | gemma3:27b | 17 GB | dense | 7.9 |
| 42 | codellama:34b | 19 GB | dense | 7.8 |
| 43 | deepseek-coder:33b | 18 GB | dense | 7.5 |
| 44 | exaone-deep:32b | 19 GB | dense | 7.1 |
| 45 | qwen2.5:32b | 19 GB | dense | 7.0 |
| 46 | deepseek-r1:32b | 19 GB | dense | 6.9 |
| 47 | qwq:32b | 19 GB | dense | 6.9 |
| 48 | aya-expanse:32b | 19 GB | dense | 6.8 |
| 49 | qwen3-vl:32b | 20 GB | dense | 6.8 |

_Arch labels: MoE = mixture-of-experts (few active params); hybrid = Mamba/attention hybrid;
dense = all params active per token._
</details>

---

## Related

- [Setup.md](Setup.md) — running these models on the GX10
- [Hardware.md](Hardware.md) — why bandwidth, not capacity, is the limit here
- [../../shared/Models_and_Benchmarks.md](../../shared/Models_and_Benchmarks.md) — full RTX 3090 model catalog
- [../../MACHINES.md](../../MACHINES.md) — machine comparison
