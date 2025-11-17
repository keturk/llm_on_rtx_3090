# LLM Performance Benchmarks - RTX 3090 (24GB)

Comprehensive performance testing of various large language models on NVIDIA RTX 3090 with 24GB VRAM. All models tested run **entirely on GPU** with no CPU offloading.

---

## System Configuration

```
CPU:     Intel Xeon W-2235 (6 cores / 12 threads, 3.8-4.6 GHz)
RAM:     128 GB DDR4 ECC
GPU:     NVIDIA RTX 3090 (24 GB GDDR6X)
Driver:  NVIDIA 570.195.03
CUDA:    12.8
Backend: Ollama (Docker)
OS:      Ubuntu 24.04.3 LTS
```

---

## Quick Reference Table

| Model | Parameters | VRAM | GPU Util | Tokens/sec | Best For |
|-------|-----------|------|----------|------------|----------|
| **llama3.2:3b** | 3B | ~2GB | 60-80% | 50-60 | Quick responses, testing |
| **mistral:7b** | 7B | ~4GB | 65-85% | 45-55 | General use, fast |
| **qwen2.5:7b** | 7B | ~5GB | 70-85% | 40-50 | Coding, reasoning |
| **llama3.1:8b** | 8B | ~5GB | 70-85% | 40-50 | Daily use, balanced |
| **phi3:14b** | 14B | ~8GB | 75-90% | 30-40 | Long context (128k) |
| **qwen2.5:14b** | 14B | ~9GB | 80-90% | 30-40 | High quality |
| **gemma2:27b** | 27B | ~15GB | 85-95% | 20-30 | Excellent quality |
| **qwen2.5:32b** | 32B | ~21GB | 80-97% | 15-25 | Maximum quality |
| **codellama:34b** | 34B | ~18GB | 85-95% | 12-20 | Code generation |
| **deepseek-coder:33b** | 33B | ~17GB | 85-95% | 12-20 | Advanced coding |

---

## Detailed Analysis

### Small Models (3-8B) - Speed Focused

#### llama3.2:3b
- **VRAM:** ~2 GB
- **Speed:** 50-60 tokens/sec
- **Quality:** Good
- **Best for:** Prototyping, quick queries, high-volume simple tasks
- **Trade-offs:** Lower reasoning capability, shorter context

#### mistral:7b (v0.3)
- **VRAM:** ~4 GB
- **Speed:** 45-55 tokens/sec
- **Quality:** Very Good
- **Best for:** General assistant tasks, summarization
- **Trade-offs:** Good balance but outperformed by Qwen for coding

#### qwen2.5:7b
- **VRAM:** ~5 GB
- **Speed:** 40-50 tokens/sec
- **Quality:** Very Good
- **Best for:** Coding assistance, technical reasoning
- **Trade-offs:** Slightly slower than Mistral, better at structured tasks

#### llama3.1:8b
- **VRAM:** ~5 GB
- **Speed:** 40-50 tokens/sec
- **Quality:** Very Good
- **Best for:** General purpose, daily driver
- **Trade-offs:** Well-rounded but not specialized

### Medium Models (14B) - Quality Focus

#### phi3:14b (Microsoft)
- **VRAM:** ~8 GB
- **Speed:** 30-40 tokens/sec
- **Quality:** Excellent
- **Best for:** Long documents (128k context), research
- **Trade-offs:** More resource efficient, strong reasoning

#### qwen2.5:14b
- **VRAM:** ~9 GB
- **Speed:** 30-40 tokens/sec
- **Quality:** Excellent
- **Best for:** Production use, complex reasoning
- **Trade-offs:** Great balance of speed and quality

### Large Models (27-34B) - Maximum Quality

#### gemma2:27b (Google)
- **VRAM:** ~15 GB (Q4 quantization)
- **Speed:** 20-30 tokens/sec
- **Quality:** Excellent+
- **Best for:** High-quality content generation
- **Trade-offs:** Excellent quality, moderate speed

#### qwen2.5:32b
- **VRAM:** ~21 GB (Q4 quantization)
- **Speed:** 15-25 tokens/sec
- **Quality:** Best (general purpose)
- **Best for:** Maximum quality non-coding tasks
- **Trade-offs:** Uses almost full VRAM, slower generation

#### codellama:34b (Meta)
- **VRAM:** ~18 GB (Q4 quantization)
- **Speed:** 12-20 tokens/sec
- **Quality:** Best (code-specific)
- **Best for:** Code generation, refactoring, debugging
- **Trade-offs:** Specialized for code, not general chat

#### deepseek-coder:33b
- **VRAM:** ~17 GB (Q4 quantization)
- **Speed:** 12-20 tokens/sec
- **Quality:** Best (advanced coding)
- **Best for:** Complex algorithms, code review
- **Trade-offs:** Specialized, excellent for technical tasks

---

## Task-Specific Recommendations

### For Chatbots & Quick Responses
```
1st choice: mistral:7b (fast, good quality)
2nd choice: llama3.2:3b (fastest, acceptable quality)
```

### For Coding Assistance
```
Quick edits: qwen2.5:7b (fast, good code)
Complex code: deepseek-coder:33b or codellama:34b (best quality)
Balanced: qwen2.5:14b (good speed, excellent code)
```

### For Document Analysis
```
Short docs: llama3.1:8b (fast, reliable)
Long docs: phi3:14b (128k context support)
Quality focus: qwen2.5:32b (best reasoning)
```

### For Creative Writing
```
Speed priority: mistral:7b
Quality priority: qwen2.5:32b or gemma2:27b
```

---

## VRAM Usage Breakdown

```
24 GB Total VRAM
├── 2-5 GB    → 3B-8B models (3+ models can fit)
├── 8-9 GB    → 14B models (2 models can fit)
├── 15-18 GB  → 27B-34B models (only 1 model fits)
└── 21 GB     → 32B model (uses 87% VRAM)
```

### Memory Management Tips

1. **Model Loading Time:**
   - 3B models: ~2-3 seconds
   - 14B models: ~5-8 seconds
   - 32B models: ~15-20 seconds

2. **Switching Models:**
   - Ollama auto-unloads after 5 minutes of inactivity
   - Force unload: `ollama stop model-name`

3. **Concurrent Usage:**
   - Can run multiple small models simultaneously
   - Large models (20GB+) should run exclusively

---

## Temperature & Power Consumption

| Model Size | Idle Power | Peak Power | Temp Range |
|------------|-----------|------------|------------|
| 3B | 30W | 100-150W | 35-45°C |
| 7-8B | 30W | 150-200W | 40-50°C |
| 14B | 30W | 200-250W | 45-55°C |
| 27-32B | 30W | 250-300W | 50-65°C |
| 33-34B | 30W | 280-320W | 55-68°C |

**Thermal Throttling:** RTX 3090 throttles at 83°C. Sustained loads with large models should maintain <70°C with good airflow.

---

## Quantization Impact

Testing shows Q4 quantization provides optimal balance:

| Quantization | Quality Loss | Speed Gain | VRAM Savings |
|--------------|--------------|------------|--------------|
| FP16 | 0% (baseline) | 1x | 1x |
| Q8 | <1% | 1.2x | 2x |
| Q4 | 3-5% | 1.5x | 4x |
| Q2 | 15-20% | 1.7x | 8x |

**Recommendation:** Always use Q4 for 24GB VRAM. Q2 only if you absolutely need 70B+ models (not recommended).

---

## API Performance

All models accessible via REST API at `http://localhost:11434`:

```bash
# Streaming response
curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5:14b",
  "prompt": "Your prompt here",
  "stream": true
}'
```

### Latency Characteristics
- **First token:** 100-500ms (model size dependent)
- **Streaming:** Near real-time feel for all models
- **Batch processing:** Limited by GPU memory

---

## Models NOT Recommended for RTX 3090

These models will NOT run well on 24GB VRAM:

| Model | Required VRAM | Issue |
|-------|--------------|-------|
| llama3.1:70b | 26GB+ (Q4) | CPU offloading, 1-5 tok/s |
| qwen2.5:72b | 36GB+ (Q4) | Won't load, crashes |
| mixtral:8x7b | 28GB+ | Mixture of experts too large |

**For 70B+ models:** Consider dual RTX 3090 setup or RTX 4090/A100.

---

## Benchmarking Scripts

Run your own benchmarks:

```bash
# Download test models
./scripts/pull-benchmark-models.sh

# Run comprehensive benchmark
./scripts/comprehensive-benchmark.sh

# Results saved to ./benchmark_results/
```

---

## Key Findings

1. **Sweet Spot Models:**
   - **Speed priority:** mistral:7b or llama3.1:8b
   - **Quality priority:** qwen2.5:32b
   - **Balanced:** qwen2.5:14b

2. **VRAM Efficiency:**
   - 32B is the maximum model size that fits comfortably
   - 34B models work but leave little headroom
   - Q4 quantization is essential for large models

3. **Performance Patterns:**
   - GPU utilization scales with model complexity
   - Smaller models have higher tokens/sec but lower quality
   - Temperature management crucial for sustained use

4. **Best Value:**
   - qwen2.5:14b offers best quality-to-resource ratio
   - phi3:14b excellent for long-context tasks
   - codellama:34b/deepseek-coder:33b best for coding

---

## Contributing Benchmarks

Have different hardware? Contributions welcome! Please include:
- Complete system specs
- Model versions tested
- Benchmark methodology
- Raw performance numbers

---

**Last Updated:** November 2025  
**Hardware:** Dell T5820 + RTX 3090 (24GB)  
**Methodology:** Multiple runs per model, averaged results
