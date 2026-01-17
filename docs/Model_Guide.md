# Model Selection Guide (RTX 3090 24GB)

**Quick Reference Guide** - For detailed benchmarks and technical analysis, see [Models_And_Benchmarks.md](Models_And_Benchmarks.md)

**Last Updated:** January 2026 - Based on 48 model comprehensive benchmark

This guide helps you quickly choose the right models for your RTX 3090. All models listed have been tested and validated.

---

## Quick Recommendations by Use Case

| Use Case | Fast (60-90 tok/s) | Balanced (30-60 tok/s) | Quality (20-30 tok/s) |
|----------|-------------------|----------------------|---------------------|
| **General Chat** | exaone-deep:7.8b | qwen3:8b | qwen2.5:32b |
| **Reasoning** | marco-o1:7b | deepseek-r1:14b | deepseek-r1:32b |
| **Coding** | qwen2.5:7b | qwen2.5-coder:14b | deepseek-coder:33b |
| **Vision/Multimodal** | qwen3-vl:8b | gemma3:12b | qwen3-vl:32b |
| **Multilingual** | aya-expanse:8b | glm4:9b | aya-expanse:32b |
| **Long Context** | phi3:14b | phi4 | qwen2.5:32b |

> 📊 **Need more options?** See [complete model tables](Models_And_Benchmarks.md#quick-reference) with all 48 tested models.

---

## Top Speed Models

### 🏆 Fastest: EXAONE-Deep 7.8B
- **Speed**: **90.1 tok/s** (fastest tested!)
- **VRAM**: ~5GB
- **Use**: Maximum speed, general chat
- **Pull**: `ollama pull exaone-deep:7.8b`

### 🚀 Other Speed Champions (60-70 tok/s)
- **marco-o1:7b** - 68.9 tok/s (reasoning specialist)
- **granite3.1-moe:3b** - 65.7 tok/s (tiny MoE, ~2GB)
- **smollm2:1.7b** - 64.6 tok/s (smallest, ~3GB)
- **mistral:7b** - 64.7 tok/s (proven reliability)
- **qwen3:8b** - 62.1 tok/s (next-gen balanced)
- **deepseek-r1:8b** - 60.9 tok/s (reasoning with thinking)

> 📈 **See all speed rankings:** [Models_And_Benchmarks.md#quick-reference](Models_And_Benchmarks.md#quick-reference)

---

## Models by Size Category

### Small Models (1.7-8B) - Speed Priority
**Top picks:** exaone-deep:7.8b (90.1 tok/s), marco-o1:7b (68.9 tok/s), qwen3:8b (62.1 tok/s)

| Model | VRAM | Speed | Best For |
|-------|------|-------|----------|
| exaone-deep:7.8b 🆕 | ~5GB | 90.1 | Fastest overall |
| marco-o1:7b 🆕 | ~5GB | 68.9 | Fast reasoning |
| mistral:7b | ~5GB | 64.7 | General use |
| qwen3:8b 🆕 | ~5GB | 62.1 | Next-gen |
| llama3.1:8b | ~5GB | 42.8 | Daily driver |
| qwen3-vl:8b 🆕 | ~7GB | 40.9 | Vision |

> 📋 **See all 20 small models:** [Models_And_Benchmarks.md#detailed-model-analysis](Models_And_Benchmarks.md#detailed-model-analysis)

### Medium Models (10-14B) - Balanced
**Top picks:** deepseek-r1:14b (56.6 tok/s), qwen3:14b (43.2 tok/s), phi3:14b (38.7 tok/s)

| Model | VRAM | Speed | Best For |
|-------|------|-------|----------|
| deepseek-r1:14b 🆕 | ~9GB | 56.6 | Best reasoning value |
| qwen3:14b 🆕 | ~9GB | 43.2 | High quality |
| phi3:14b | ~9GB | 38.7 | Long context (128k) |
| qwen2.5-coder:14b | ~9GB | 29.2 | Coding |
| qwen2.5:14b | ~9GB | 29.2 | Production |

> 📋 **See all 10 medium models:** [Models_And_Benchmarks.md#detailed-model-analysis](Models_And_Benchmarks.md#detailed-model-analysis)

### Large Models (22-34B) - Maximum Quality
**Top picks:** qwen3:30b-a3b (43.7 tok/s MoE), deepseek-r1:32b (29.8 tok/s), qwen2.5:32b (21.4 tok/s)

| Model | VRAM | Speed | Best For |
|-------|------|-------|----------|
| qwen3:30b-a3b 🆕 | ~18GB | 43.7 | MoE - fast! |
| deepseek-r1:32b 🆕 | ~19GB | 29.8 | Max reasoning |
| qwen2.5:32b | ~19GB | 21.4 | Max quality |
| deepseek-coder:33b | ~18GB | 21.5 | Elite coding |

> 📋 **See all 15 large models:** [Models_And_Benchmarks.md#detailed-model-analysis](Models_And_Benchmarks.md#detailed-model-analysis)

---

## Specialized Models

### 🆕 Vision/Multimodal
- **qwen3-vl:8b** - 40.9 tok/s (~7GB) - Text + image
- **qwen3-vl:32b** - 22.1 tok/s (~23GB) - Advanced vision
- **gemma3 series** - 4B/12B/27B sizes available

### 🧠 Reasoning (Chain-of-Thought)
- **deepseek-r1:8b** - 60.9 tok/s (~5GB) - Fast reasoning
- **deepseek-r1:14b** - 56.6 tok/s (~9GB) - **Best value** ⭐
- **deepseek-r1:32b** - 29.8 tok/s (~19GB) - Maximum quality

### 🌍 Multilingual
- **aya-expanse:8b** - 32.0 tok/s (~6GB) - 10+ languages
- **aya-expanse:32b** - 20.9 tok/s (~20GB) - Large multilingual
- **glm4:9b** - 31.4 tok/s (~5GB) - Chinese-English

> 📖 **Detailed model descriptions:** [Models_And_Benchmarks.md#detailed-model-analysis](Models_And_Benchmarks.md#detailed-model-analysis)

---

## Quick Testing Strategy

### Phase 1: Quick Validation
```bash
ollama pull llama3.2:3b          # Fast test (52.3 tok/s)
ollama pull exaone-deep:7.8b     # Speed champion (90.1 tok/s)
```

### Phase 2: Category Testing
```bash
ollama pull deepseek-r1:14b      # Reasoning (56.6 tok/s)
ollama pull qwen2.5-coder:14b    # Coding (29.2 tok/s)
ollama pull qwen3-vl:8b          # Vision (40.9 tok/s)
ollama pull qwen3:14b            # General quality (43.2 tok/s)
```

### Phase 3: Maximum Quality
```bash
ollama pull qwen2.5:32b          # Max general (21.4 tok/s)
ollama pull deepseek-r1:32b      # Max reasoning (29.8 tok/s)
ollama pull deepseek-coder:33b   # Elite coding (21.5 tok/s)
```

> 🔬 **Comprehensive testing guide:** [Models_And_Benchmarks.md#testing-strategy](Models_And_Benchmarks.md#testing-strategy)

---

## Quick Reference: VRAM & Quantization

### VRAM Planning
```
24 GB Total VRAM
├── 2-5 GB    → Small models (1.7-8B)   - Can run 3+ simultaneously
├── 5-10 GB   → Medium models (10-14B)  - Run 2 models
├── 13-20 GB  → Large models (22-32B)   - Run 1 model only
└── 20-24 GB  → Maximum (32-34B)        - Single model, uses ~87-96% VRAM
```

### Quantization
**Recommendation:** Use Q4 (default in Ollama) - optimal balance of quality and VRAM usage.

| Quant | Quality Loss | VRAM Savings | Use When |
|-------|--------------|---------------|----------|
| Q4 ⭐ | ~3-5% | 4x | **Sweet spot** (recommended) |
| Q8 | <1% | 2x | Quality critical |
| Q2 | ~15-20% | 8x | Last resort (70B+ models) |

> 🔧 **Detailed technical specs:** [Models_And_Benchmarks.md#vram-usage--planning](Models_And_Benchmarks.md#vram-usage--planning) and [Quantization Impact](Models_And_Benchmarks.md#quantization-impact)

---

## Quick Commands

```bash
# List installed models
ollama list

# Pull a model
ollama pull exaone-deep:7.8b

# Test a model
ollama run exaone-deep:7.8b "What is quantum computing?"

# Remove a model
ollama rm <model-name>

# Check VRAM usage
nvidia-smi
```

---

## Related Documentation

- **[Models_And_Benchmarks.md](Models_And_Benchmarks.md)** - Complete benchmark data, detailed model analysis, technical specifications
- **[Benchmark_Automation.md](Benchmark_Automation.md)** - Automated benchmarking workflow
- **[Install.md](Install.md)** - Installation walkthrough

---

**Need more details?** This is a quick reference guide. For comprehensive benchmarks, detailed model descriptions, temperature/power data, and full technical analysis, see [Models_And_Benchmarks.md](Models_And_Benchmarks.md).
