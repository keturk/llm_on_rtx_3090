# Model Selection Guide (RTX 3090 24GB)

**Quick Reference Guide** - For detailed benchmarks and technical analysis, see [Models_and_Benchmarks.md](Models_and_Benchmarks.md)

**Last Updated:** July 2026 - 59 models documented (48 benchmarked + 11 new)

This guide helps you quickly choose the right models for your RTX 3090. All models listed have been tested and validated.

---

## Quick Recommendations by Use Case

| Use Case | Fast (60-90 tok/s) | Balanced (30-60 tok/s) | Quality (Best) |
|----------|-------------------|----------------------|---------------------|
| **General Chat** | exaone-deep:7.8b | qwen3:8b | qwen3.6:27b |
| **Reasoning** | marco-o1:7b | deepseek-r1:14b | gemma4:31b |
| **Coding** | qwen2.5:7b | devstral:24b | qwen3.6:27b |
| **Vision/Multimodal** | qwen3-vl:8b | gemma4:12b | gemma4:31b |
| **Multilingual** | aya-expanse:8b | glm4:9b | aya-expanse:32b |
| **Long Context** | phi3:14b | mistral-small3.1:24b | qwen3.6:27b (256K) |
| **Tool Calling** | gpt-oss:20b | mistral-small3.2:24b | gemma4:26b |
| **Coding Agents** | gpt-oss:20b | devstral:24b | devstral-small-2:24b |

> 📊 **Need more options?** See [complete model tables](Models_and_Benchmarks.md#quick-reference) with all 59 documented models.

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

> 📈 **See all speed rankings:** [Models_and_Benchmarks.md#quick-reference](Models_and_Benchmarks.md#quick-reference)

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

> 📋 **See all small models:** [Models_and_Benchmarks.md#detailed-model-analysis](Models_and_Benchmarks.md#detailed-model-analysis)

### Medium Models (10-20B) - Balanced
**Top picks:** deepseek-r1:14b (56.6 tok/s), qwen3:14b (43.2 tok/s), gpt-oss:20b (tool calling)

| Model | VRAM | Speed | Best For |
|-------|------|-------|----------|
| deepseek-r1:14b 🆕 | ~9GB | 56.6 | Best reasoning value |
| qwen3:14b 🆕 | ~9GB | 43.2 | High quality |
| phi3:14b | ~9GB | 38.7 | Long context (128k) |
| qwen2.5-coder:14b | ~9GB | 29.2 | Coding |
| gemma4:12b 🆕🆕 | ~7GB | TBD | Google's latest, tool calling |
| gpt-oss:20b 🆕🆕 | ~14GB | TBD | OpenAI MoE, best tool calling |

> 📋 **See all medium models:** [Models_and_Benchmarks.md#detailed-model-analysis](Models_and_Benchmarks.md#detailed-model-analysis)

### Large Models (22-35B) - Maximum Quality
**Top picks:** qwen3.6:27b (latest Qwen), devstral:24b (coding), gemma4:31b (reasoning)

| Model | VRAM | Speed | Best For |
|-------|------|-------|----------|
| qwen3:30b-a3b 🆕 | ~18GB | 43.7 | MoE - fast! |
| deepseek-r1:32b 🆕 | ~19GB | 29.8 | Max reasoning |
| devstral:24b 🆕🆕 | ~14GB | TBD | SWE-Bench champion |
| devstral-small-2:24b 🆕🆕 | ~15GB | TBD | Coding agent, 384K ctx |
| mistral-small3.2:24b 🆕🆕 | ~15GB | TBD | Function calling |
| gemma4:31b 🆕🆕 | ~20GB | TBD | Google's best dense |
| qwen3.6:27b 🆕🆕 | ~17GB | TBD | Latest Qwen, 256K ctx |
| qwen3.6:35b 🆕🆕 | ~24GB | TBD | Latest Qwen MoE |

> 📋 **See all large models:** [Models_and_Benchmarks.md#detailed-model-analysis](Models_and_Benchmarks.md#detailed-model-analysis)

---

## Specialized Models

### 🆕 Vision/Multimodal
- **qwen3-vl:8b** - 40.9 tok/s (~7GB) - Text + image
- **qwen3-vl:32b** - 22.1 tok/s (~23GB) - Advanced vision
- **gemma4:12b** 🆕🆕 - TBD (~7GB) - Google's latest with vision + tool calling
- **gemma4:31b** 🆕🆕 - TBD (~20GB) - Best Google multimodal
- **mistral-small3.1:24b** 🆕🆕 - TBD (~15GB) - Mistral multimodal, 128K

### 🧠 Reasoning (Chain-of-Thought)
- **deepseek-r1:8b** - 60.9 tok/s (~5GB) - Fast reasoning
- **deepseek-r1:14b** - 56.6 tok/s (~9GB) - **Best value** ⭐
- **deepseek-r1:32b** - 29.8 tok/s (~19GB) - Maximum quality
- **gemma4:31b** 🆕🆕 - TBD (~20GB) - Frontier-level reasoning

### 💻 Coding & Software Engineering
- **qwen2.5-coder:14b** - 29.2 tok/s (~9GB) - Coding specialist
- **devstral:24b** 🆕🆕 - TBD (~14GB) - SWE-Bench 46.8%, agentic coding
- **devstral-small-2:24b** 🆕🆕 - TBD (~15GB) - 384K context, multi-file editing
- **qwen3.6:27b** 🆕🆕 - TBD (~17GB) - Best coding experience

### 🔧 Tool Calling & Agents
- **gpt-oss:20b** 🆕🆕 - TBD (~14GB) - **Cleanest tool-call JSON** ⭐
- **mistral-small3.2:24b** 🆕🆕 - TBD (~15GB) - Improved function calling
- **gemma4:12b** 🆕🆕 - TBD (~7GB) - Built-in tool calling
- **nemotron-mini:4b** - 50.2 tok/s (~3GB) - Compact RAG/function calling

### 🌍 Multilingual
- **aya-expanse:8b** - 32.0 tok/s (~6GB) - 10+ languages
- **aya-expanse:32b** - 20.9 tok/s (~20GB) - Large multilingual
- **glm4:9b** - 31.4 tok/s (~5GB) - Chinese-English

> 📖 **Detailed model descriptions:** [Models_and_Benchmarks.md#detailed-model-analysis](Models_and_Benchmarks.md#detailed-model-analysis)

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

### Phase 4: 2026 Models
```bash
ollama pull gemma4:12b            # Google's latest, tool calling
ollama pull gpt-oss:20b           # OpenAI MoE, best tool calling
ollama pull devstral:24b          # Mistral coding agent
ollama pull devstral-small-2:24b  # Coding agent, 384K context
ollama pull mistral-small3.2:24b  # Latest Mistral, function calling
ollama pull qwen3.6:27b           # Latest Qwen, 256K context
ollama pull gemma4:31b            # Google's best dense model
```

> 🔬 **Comprehensive testing guide:** [Models_and_Benchmarks.md#testing-strategy](Models_and_Benchmarks.md#testing-strategy)

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

> 🔧 **Detailed technical specs:** [Models_and_Benchmarks.md#vram-usage--planning](Models_and_Benchmarks.md#vram-usage--planning) and [Quantization Impact](Models_and_Benchmarks.md#quantization-impact)

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

- **[Models_and_Benchmarks.md](Models_and_Benchmarks.md)** - Complete benchmark data, detailed model analysis, technical specifications
- **[Benchmark_Automation.md](Benchmark_Automation.md)** - Automated benchmarking workflow
- **[Install.md](Install.md)** - Installation walkthrough

---

**Need more details?** This is a quick reference guide. For comprehensive benchmarks, detailed model descriptions, temperature/power data, and full technical analysis, see [Models_and_Benchmarks.md](Models_and_Benchmarks.md).
