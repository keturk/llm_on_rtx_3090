# Models & Benchmarks - RTX 3090 (24GB)

**Comprehensive Technical Reference** - For quick model selection, see [Model_Guide.md](Model_Guide.md)

Complete guide to LLM selection, performance benchmarks, and recommendations for NVIDIA RTX 3090. This document contains detailed technical analysis, benchmark data, and comprehensive model descriptions.

**Last Updated:** January 2026
**Models Tested:** 48 total (1.7B to 34B parameters)
**Methodology:** Automated comprehensive benchmark suite with 5 diverse prompts per model

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

## Table of Contents
- [System Configuration](#system-configuration)
- [Quick Reference](#quick-reference)
- [Detailed Model Analysis](#detailed-model-analysis)
- [Task-Specific Recommendations](#task-specific-recommendations)
- [VRAM Usage & Planning](#vram-usage--planning)
- [Temperature & Power Consumption](#temperature--power-consumption)
- [Quantization Impact](#quantization-impact)
- [Testing Strategy](#testing-strategy)
- [Performance Benchmarks](#performance-benchmarks)
- [Key Findings](#key-findings)

---

## Quick Reference

### Top Model Recommendations by Use Case

| Use Case | Speed Priority | Balanced | Quality Priority |
|----------|---------------|----------|------------------|
| **Chat/Q&A** | llama3.2:3b | llama3.1:8b | qwen2.5:32b |
| **Coding** | qwen2.5:7b | qwen2.5-coder:14b | deepseek-coder:33b |
| **Long Context** | phi3:14b | phi3:14b | qwen2.5:32b |
| **Creative Writing** | mistral:7b | gemma2:27b | qwen2.5:32b |
| **Reasoning** | deepseek-r1:8b | deepseek-r1:14b | deepseek-r1:32b |
| **Agentic/RAG** | nemotron-mini:4b | nemotron-3-nano:30b | nemotron-3-nano:30b |

### Performance Overview (January 2026 - 48 Models Tested)

| Model | Size | VRAM | Tokens/sec | Quality | Best For |
|-------|------|------|------------|---------|----------|
| **Small Models (1.7-9B) - Speed Focused** |
| exaone-deep:7.8b 🆕 | 7.8B | ~5GB | 90.1 | Very Good | Fastest overall! |
| marco-o1:7b 🆕 | 7B | ~5GB | 68.9 | Very Good | Reasoning specialist |
| granite3.1-moe:3b | 3B | ~2GB | 65.7 | Good | Tiny MoE powerhouse |
| smollm2:1.7b 🆕 | 1.7B | ~3GB | 64.6 | Very Good | Smallest, very efficient |
| mistral:7b | 7B | ~5GB | 64.7 | Very Good | General use |
| phi4-mini | - | ~3GB | 63.2 | Good | Compact quality |
| qwen3:8b 🆕 | 8B | ~5GB | 62.1 | Very Good | Next-gen Qwen |
| deepseek-r1:8b 🆕 | 8B | ~5GB | 60.9 | Very Good | Reasoning 8B |
| llama3.2:3b | 3B | ~3GB | 52.3 | Good | Testing, quick responses |
| nemotron-mini:4b | 4B | ~3GB | 50.2 | Good | Roleplay, RAG |
| granite3-dense:8b | 8B | ~6GB | 45.3 | Very Good | Dense architecture |
| llama3.1:8b | 8B | ~5GB | 42.8 | Very Good | Daily driver |
| falcon3:7b 🆕 | 7B | ~5GB | 41.8 | Very Good | Open alternative |
| qwen3-vl:8b 🆕 | 8B | ~7GB | 40.9 | Very Good | Vision + text |
| hermes3:8b 🆕 | 8B | ~5GB | 38.2 | Very Good | Conversational |
| ministral-3:3b | 3B | ~4GB | 36.0 | Good | Edge, agentic, vision |
| dolphin3 | 8B | ~5GB | 36.2 | Good | Open assistant |
| qwen2.5:7b | 7B | ~5GB | 34.7 | Very Good | Coding, reasoning |
| aya-expanse:8b 🆕 | 8B | ~6GB | 32.0 | Very Good | Multilingual |
| glm4:9b 🆕 | 9B | ~5GB | 31.4 | Good | Chinese-English |
| ministral-3:8b | 8B | ~7GB | 30.8 | Very Good | Agentic, vision |
| gemma3:4b 🆕 | 4B | ~4GB | 27.7 | Good | Multimodal compact |
| **Medium Models (10-14B) - Balanced** |
| deepseek-r1:14b 🆕 | 14B | ~9GB | 56.6 | Excellent | Best reasoning value |
| qwen3:14b 🆕 | 14B | ~9GB | 43.2 | Excellent | Enhanced quality |
| phi3:14b | 14B | ~9GB | 38.7 | Excellent | Long context (128k) |
| falcon3:10b 🆕 | 10B | ~7GB | 37.2 | Good | Open medium |
| phi4 | 14B | ~10GB | 34.1 | Excellent | Latest Microsoft |
| olmo2:13b 🆕 | 13B | ~11GB | 33.9 | Good | Open research |
| qwen2.5-coder:14b | 14B | ~9GB | 29.2 | Excellent | Coding specialist |
| qwen2.5:14b | 14B | ~9GB | 29.2 | Excellent | Production quality |
| ministral-3:14b | 14B | ~10GB | 23.1 | Excellent | Vision + function calling |
| gemma3:12b 🆕 | 12B | ~9GB | 22.0 | Excellent | Multimodal balanced |
| **Large Models (22-34B) - Maximum Quality** |
| qwen3:30b-a3b 🆕 | 30B MoE | ~18GB | 43.7 | Excellent+ | MoE - fast for size! |
| codestral:22b | 22B | ~13GB | 35.4 | Good | Code specialist |
| nemotron-3-nano:30b | 30B | ~23GB | 33.5 | Excellent+ | Large efficient |
| exaone-deep:32b 🆕 | 32B | ~19GB | 33.3 | Best | Reasoning 32B |
| qwq:32b | 32B | ~19GB | 30.2 | Best | Deep reasoning |
| deepseek-r1:32b 🆕 | 32B | ~19GB | 29.8 | Best | Max reasoning quality |
| mistral-small:24b | 24B | ~14GB | 25.1 | Good | Sub-70B champion |
| qwen3-coder:30b 🆕 | 30B | ~18GB | 24.3 | Excellent+ | Advanced coding |
| codellama:34b | 34B | ~19GB | 23.9 | Best | Code generation |
| qwen3-vl:32b 🆕 | 32B | ~23GB | 22.1 | Best | Vision + text large |
| qwen2.5:32b | 32B | ~19GB | 21.4 | Best | Maximum quality |
| deepseek-coder:33b | 33B | ~18GB | 21.5 | Best | Elite coding |
| aya-expanse:32b 🆕 | 32B | ~20GB | 20.9 | Best | Multilingual large |
| gemma2:27b | 27B | ~17GB | 20.4 | Excellent+ | Google's best |
| gemma3:27b 🆕 | 27B | ~17GB | 18.0 | Excellent+ | Multimodal large |

---

## Detailed Model Analysis

### Small Models (3-8B) - Speed Focused

#### llama3.2:3b
- **VRAM:** ~2GB | **Speed:** 50-60 tok/s | **Quality:** Good
- **Best for:** Prototyping, quick queries, high-volume simple tasks
- **Trade-offs:** Lower reasoning, shorter context
- **Ollama:** `llama3.2:3b` | **HF:** `meta-llama/Llama-3.2-3B-Instruct`

#### mistral:7b
- **VRAM:** ~4GB | **Speed:** 45-55 tok/s | **Quality:** Very Good
- **Best for:** General assistant, summarization
- **Trade-offs:** Good balance, outperformed by Qwen for coding
- **Ollama:** `mistral:7b` | **HF:** `mistralai/Mistral-7B-Instruct-v0.3`

#### qwen2.5:7b
- **VRAM:** ~5GB | **Speed:** 40-50 tok/s | **Quality:** Very Good
- **Best for:** Coding assistance, technical reasoning
- **Trade-offs:** Slightly slower, better at structured tasks
- **Ollama:** `qwen2.5:7b` | **HF:** `Qwen/Qwen2.5-7B-Instruct`

#### llama3.1:8b
- **VRAM:** ~5GB | **Speed:** 40-50 tok/s | **Quality:** Very Good
- **Best for:** General purpose daily driver
- **Trade-offs:** Well-rounded but not specialized
- **Ollama:** `llama3.1:8b` | **HF:** `meta-llama/Llama-3.1-8B-Instruct`

#### 🆕 qwen3:8b (2025)
- **VRAM:** ~5GB | **Speed:** 40-50 tok/s | **Quality:** Very Good
- **Best for:** Next-generation Qwen, improved reasoning
- **Trade-offs:** Newer model, less community testing
- **Ollama:** `qwen3:8b`

#### 🆕 deepseek-r1:8b (2025)
- **VRAM:** ~5GB | **Speed:** 35-45 tok/s | **Quality:** Very Good
- **Best for:** Reasoning tasks, chain-of-thought
- **Trade-offs:** Specialized for reasoning, slightly slower
- **Ollama:** `deepseek-r1:8b`

#### 🆕 gemma3:4b (2025)
- **VRAM:** ~3GB | **Speed:** 45-55 tok/s | **Quality:** Good
- **Best for:** Multimodal tasks, compact size
- **Trade-offs:** Smaller parameter count
- **Ollama:** `gemma3:4b`

#### 🆕 nemotron-mini:4b (2025)
- **VRAM:** ~3GB | **Speed:** 45-55 tok/s | **Quality:** Very Good
- **Best for:** Roleplay, RAG (retrieval augmented generation), function calling
- **Trade-offs:** Optimized through distillation, pruning and quantization
- **Ollama:** `nemotron-mini:4b`
- **Context:** 4,096 tokens
- **Languages:** English

#### 🆕 ministral-3:3b (2025)
- **VRAM:** ~2GB | **Speed:** 50-60 tok/s | **Quality:** Good
- **Best for:** Edge deployment, agentic AI, vision capabilities
- **Trade-offs:** Smaller model, edge-focused
- **Ollama:** `ministral-3:3b`
- **Features:** Vision support, function calling, JSON output
- **Languages:** Multilingual (English, French, Spanish, German, etc.)

### Medium Models (12-14B) - Balanced

#### phi3:14b
- **VRAM:** ~8GB | **Speed:** 30-40 tok/s | **Quality:** Excellent
- **Best for:** Long documents (128k context), research
- **Trade-offs:** Resource efficient, strong reasoning
- **Ollama:** `phi3:14b` | **HF:** `microsoft/Phi-3-medium-128k-instruct`

#### qwen2.5:14b
- **VRAM:** ~9GB | **Speed:** 30-40 tok/s | **Quality:** Excellent
- **Best for:** Production use, complex reasoning
- **Trade-offs:** Great balance of speed and quality
- **Ollama:** `qwen2.5:14b` | **HF:** `Qwen/Qwen2.5-14B-Instruct`

#### 🆕 qwen3:14b (2025)
- **VRAM:** ~9GB | **Speed:** 30-40 tok/s | **Quality:** Excellent
- **Best for:** Enhanced quality over qwen2.5
- **Ollama:** `qwen3:14b`

#### 🆕 deepseek-r1:14b (2025)
- **VRAM:** ~9GB | **Speed:** 25-35 tok/s | **Quality:** Excellent
- **Best for:** Best value for reasoning tasks
- **Trade-offs:** Slower but superior reasoning
- **Ollama:** `deepseek-r1:14b`

#### 🆕 gemma3:12b (2025)
- **VRAM:** ~8GB | **Speed:** 32-42 tok/s | **Quality:** Excellent
- **Best for:** Multimodal balanced performance
- **Ollama:** `gemma3:12b`

#### qwen2.5-coder:14b
- **VRAM:** ~9GB | **Speed:** 30-40 tok/s | **Quality:** Excellent
- **Best for:** Coding specialist
- **Ollama:** `qwen2.5-coder:14b`

#### 🆕 phi4:14b (2025)
- **VRAM:** ~9GB | **Speed:** 30-40 tok/s | **Quality:** Excellent
- **Best for:** Complex reasoning tasks, rivals larger models
- **Trade-offs:** State-of-the-art reasoning for 14B size class
- **Ollama:** `phi4`
- **Features:** Microsoft's latest, improved reasoning capabilities
- **Storage:** 9.1GB

#### 🆕 ministral-3:8b (2025)
- **VRAM:** ~5GB | **Speed:** 40-50 tok/s | **Quality:** Very Good
- **Best for:** Agentic AI, vision tasks, function calling
- **Trade-offs:** Edge-optimized, multimodal
- **Ollama:** `ministral-3:8b`
- **Features:** Vision support, function calling, multilingual

#### 🆕 ministral-3:14b (2025)
- **VRAM:** ~9GB | **Speed:** 30-40 tok/s | **Quality:** Excellent
- **Best for:** Advanced agentic AI, vision analysis
- **Trade-offs:** Larger Ministral variant
- **Ollama:** `ministral-3:14b`
- **Features:** Vision support, function calling, JSON output

### Large Models (24-34B) - Maximum Quality

#### 🆕 mistral-small:24b (2025)
- **VRAM:** ~14GB (Q4) | **Speed:** 25-35 tok/s | **Quality:** Excellent+
- **Best for:** Best-in-class for sub-70B models
- **Trade-offs:** Rivals Llama 3.3 70B, very knowledge-dense
- **Ollama:** `mistral-small:24b`
- **Features:** Apache 2.0 license, multilingual (10+ languages)
- **Release:** January 2025

#### gemma2:27b
- **VRAM:** ~15GB (Q4) | **Speed:** 20-30 tok/s | **Quality:** Excellent+
- **Best for:** High-quality content generation
- **Ollama:** `gemma2:27b` | **HF:** `google/gemma-2-27b-it`

#### 🆕 gemma3:27b (2025)
- **VRAM:** ~17GB (Q4) | **Speed:** 18-28 tok/s | **Quality:** Excellent+
- **Best for:** Multimodal large model
- **Ollama:** `gemma3:27b`

#### 🆕 qwen3:30b-a3b (2025)
- **VRAM:** ~18GB (MoE) | **Speed:** 22-32 tok/s | **Quality:** Excellent+
- **Best for:** Mixture of Experts - fast for size
- **Trade-offs:** MoE architecture, efficient inference
- **Ollama:** `qwen3:30b-a3b`

#### 🆕 nemotron-3-nano:30b (2025)
- **VRAM:** ~18GB (MoE Q4) | **Speed:** 25-35 tok/s | **Quality:** Excellent+
- **Best for:** Agentic AI, reasoning tasks
- **Trade-offs:** Hybrid Mamba-Transformer MoE, only 3.5B active per task
- **Ollama:** `nemotron-3-nano:30b` or `nemotron-3-nano:30b-cloud` (1M context)
- **Features:** 4x faster than Nemotron 2, 1M token context, multilingual
- **Languages:** English, German, Spanish, French, Italian, Japanese
- **Architecture:** 31.6B total parameters, 3.2B active (3.6B with embeddings)

#### 🆕 nemotron-3-nano:30b-a3b (2025)
- **VRAM:** ~18GB (MoE Q4) | **Speed:** 25-35 tok/s | **Quality:** Excellent+
- **Best for:** Agentic AI with highest accuracy for coding, reasoning, math
- **Trade-offs:** MoE variant with 3B active parameters for efficiency
- **Ollama:** `nemotron-3-nano:30b-a3b`
- **Features:** 4x faster throughput vs Nemotron 2, leading accuracy, agent-optimized
- **Specialties:** Coding, reasoning, math, long context tasks
- **Architecture:** 30B total, ~3B active per token (MoE)

#### qwen2.5:32b
- **VRAM:** ~21GB (Q4) | **Speed:** 15-25 tok/s | **Quality:** Best
- **Best for:** Maximum quality non-coding tasks
- **Trade-offs:** Uses 87% VRAM, slower generation
- **Ollama:** `qwen2.5:32b` | **HF:** `Qwen/Qwen2.5-32B-Instruct`

#### 🆕 deepseek-r1:32b (2025)
- **VRAM:** ~19GB (Q4) | **Speed:** 15-25 tok/s | **Quality:** Best
- **Best for:** Best reasoning quality available
- **Ollama:** `deepseek-r1:32b`

#### codellama:34b
- **VRAM:** ~18GB (Q4) | **Speed:** 12-20 tok/s | **Quality:** Best
- **Best for:** Code generation, refactoring, debugging
- **Trade-offs:** Specialized for code, not general chat
- **Ollama:** `codellama:34b` | **HF:** `meta-llama/CodeLlama-34b-Instruct-hf`

#### deepseek-coder:33b
- **VRAM:** ~17GB (Q4) | **Speed:** 12-20 tok/s | **Quality:** Best
- **Best for:** Complex algorithms, code review
- **Ollama:** `deepseek-coder:33b` | **HF:** `deepseek-ai/deepseek-coder-33b-instruct`

### Very Large Models (70B+) - Advanced Reasoning

> **Note:** These models are too large for RTX 3090 24GB in Q4 quantization. They require Q2 quantization (significant quality loss) or multiple GPUs.

#### 🆕 llama3.3:70b (2025)
- **VRAM:** ~43GB (Q4), ~24GB (Q2)
- **Speed:** ~5-10 tok/s (Q2 on RTX 3090)
- **Quality:** Best (Q4), Degraded (Q2)
- **Best for:** State-of-the-art performance, rivals Llama 3.1 405B
- **Trade-offs:** Too large for single RTX 3090 without severe quantization
- **Ollama:** `llama3.3:70b` or `llama3.3:70b-q2`
- **Storage:** 43GB (Q4)
- **Recommendation:** Use on multi-GPU setup or A100/H100

#### 🆕 qwq:32b (2025)
- **VRAM:** ~20GB (Q4) | **Speed:** 15-25 tok/s | **Quality:** Excellent+
- **Best for:** Advanced reasoning tasks, Qwen reasoning specialist
- **Trade-offs:** Reasoning-focused variant of Qwen series
- **Ollama:** `qwq`
- **Features:** Deep reasoning capabilities, part of Qwen family
- **Note:** Fits on RTX 3090 with Q4 quantization

---

## Task-Specific Recommendations

### Chatbots & Quick Responses
```
1st choice: mistral:7b (fast, good quality)
2nd choice: llama3.2:3b (fastest, acceptable quality)
3rd choice: llama3.1:8b (balanced)
```

### Coding Assistance
```
Quick edits: qwen2.5:7b (fast, good code)
Balanced: qwen2.5-coder:14b (good speed, excellent code)
Complex code: deepseek-coder:33b or codellama:34b (best quality)
```

### Document Analysis
```
Short docs: llama3.1:8b (fast, reliable)
Long docs: phi3:14b (128k context support)
Quality focus: qwen2.5:32b (best reasoning)
```

### Creative Writing
```
Speed priority: mistral:7b
Balanced: gemma2:27b or gemma3:27b
Quality priority: qwen2.5:32b
```

### Reasoning Tasks
```
Fast reasoning: deepseek-r1:8b
Best value: deepseek-r1:14b
Advanced reasoning: qwq:32b (Qwen reasoning specialist)
Maximum quality: deepseek-r1:32b
```

### Agentic AI & RAG
```
Compact: nemotron-mini:4b (function calling, RAG optimized)
Edge deployment: ministral-3:8b (vision, multilingual, agentic)
High performance: nemotron-3-nano:30b (1M context, hybrid MoE)
Advanced vision: ministral-3:14b (vision + function calling)
```

### Function Calling & Structured Output
```
Lightweight: nemotron-mini:4b
Balanced: ministral-3:8b (with vision)
Advanced: ministral-3:14b (JSON output, vision)
```

---

## Testing Strategy

### Phase 1: Small Models (Baseline)
Test speed and establish baseline quality:
1. `llama3.2:3b` - Fast baseline
2. `llama3.1:8b` - Quality baseline
3. `qwen2.5:7b` - Coding test

### Phase 2: Quantization Comparison
Compare same model at different quantizations:
1. `llama3.1:8b` (full precision FP16)
2. `llama3.1:8b-q4` (4-bit)
3. `llama3.1:8b-q2` (2-bit)

### Phase 3: Size Scaling
Test larger models with Q4 quantization:
1. `phi3:14b`
2. `qwen2.5:14b`
3. `gemma2:27b`

### Phase 4: Specialized Models
Test task-specific models:
1. `qwen2.5-coder:14b` (coding)
2. `deepseek-r1:14b` (reasoning)
3. `codellama:34b` or `deepseek-coder:33b` (advanced coding)

### Phase 5: 2025 Models
Test new model releases:
1. `qwen3:8b`, `qwen3:14b`, `qwen3:30b-a3b`
2. `deepseek-r1:8b`, `deepseek-r1:14b`, `deepseek-r1:32b`
3. `gemma3:4b`, `gemma3:12b`, `gemma3:27b`

---

## Performance Benchmarks

### System Configuration
```
CPU:     Intel Xeon W-2235 (6 cores / 12 threads, 3.8-4.6 GHz)
RAM:     128 GB DDR4 ECC
GPU:     NVIDIA RTX 3090 (24 GB GDDR6X)
Driver:  NVIDIA 570.195.03
CUDA:    12.8
Backend: Ollama (Docker)
OS:      Ubuntu 24.04.3 LTS
```

### VRAM Usage Breakdown
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
   - Force unload: `docker exec ollama ollama stop model-name`

3. **Concurrent Usage:**
   - Can run multiple small models simultaneously
   - Large models (20GB+) should run exclusively

### Temperature & Power Consumption

| Model Size | Idle Power | Peak Power | Temp Range |
|------------|-----------|------------|------------|
| 3B | 30W | 100-150W | 35-45°C |
| 7-8B | 30W | 150-200W | 40-50°C |
| 14B | 30W | 200-250W | 45-55°C |
| 27-32B | 30W | 250-300W | 50-65°C |
| 33-34B | 30W | 280-320W | 55-68°C |

**Thermal Throttling:** RTX 3090 throttles at 83°C. Sustained loads with large models should maintain <70°C with good airflow.

### Quantization Impact

| Quantization | Quality Loss | Speed Gain | VRAM Savings |
|--------------|--------------|------------|--------------|
| FP16 | 0% (baseline) | 1x | 1x |
| Q8 | <1% | 1.2x | 2x |
| Q6 | ~1% | 1.3x | 2.7x |
| Q5 | ~2% | 1.4x | 3.2x |
| Q4 | ~3-5% | 1.5x | 4x |
| Q3 | ~8-10% | 1.6x | 5.3x |
| Q2 | ~15-20% | 1.7x | 8x |

**Recommendation:** Always use Q4 for 24GB VRAM. Q2 only if you absolutely need 70B+ models (not recommended for quality).

---

## VRAM Usage & Planning

```
24 GB Total VRAM
├── 2-5 GB    → Small models (1.7-8B)   - Can run 3+ simultaneously
├── 5-10 GB   → Medium models (10-14B)  - Run 2 models
├── 13-20 GB  → Large models (22-32B)   - Run 1 model only
└── 20-24 GB  → Maximum (32-34B)        - Single model, uses ~87-96% VRAM
```

### Model Loading Times
- **1.7-3B models**: ~1-2 seconds
- **7-8B models**: ~3-5 seconds
- **14B models**: ~6-10 seconds
- **27-34B models**: ~15-25 seconds

### Concurrent Loading
- **Multiple small models**: 3-4 models under 8B can coexist
- **Mixed sizes**: One 14B + one 3-8B works
- **Large models**: 20GB+ models must run alone
- **Ollama auto-unload**: Models unload after 5 minutes of inactivity
- **Force unload**: `ollama stop <model-name>`

---

## Temperature & Power Consumption

| Model Size | Idle Power | Peak Power | Temp Range | Notes |
|------------|-----------|------------|------------|-------|
| 1.7-3B | 30W | 100-150W | 35-45°C | Minimal heat |
| 7-8B | 30W | 150-200W | 40-50°C | Light cooling needed |
| 10-14B | 30W | 200-250W | 45-55°C | Active cooling recommended |
| 22-27B | 30W | 250-300W | 50-65°C | Good airflow required |
| 32-34B | 30W | 280-320W | 55-68°C | Sustained loads need <70°C |

**Thermal Throttling:** RTX 3090 throttles at 83°C. For sustained workloads with large models, maintain temperatures below 70°C with adequate airflow.

---

## Key Findings (January 2026 - 48 Models)

### Performance Highlights

1. **Speed Champions:**
   - **EXAONE-Deep 7.8B**: 90.1 tok/s - fastest model ever tested on RTX 3090
   - **Marco-O1 7B**: 68.9 tok/s - fast reasoning specialist
   - **Top small models** (7-9B) now exceed 60 tok/s

2. **Best Value Models:**
   - **Overall speed**: exaone-deep:7.8b (90.1 tok/s)
   - **Balanced quality/speed**: qwen3:14b (43.2 tok/s - 48% faster than Qwen2.5)
   - **Reasoning**: deepseek-r1:14b (56.6 tok/s - shows thinking process)
   - **Coding**: qwen2.5-coder:14b or codestral:22b
   - **Vision**: qwen3-vl:8b (40.9 tok/s, 7GB VRAM)
   - **Multilingual**: aya-expanse:8b (32.0 tok/s)
   - **Smallest**: smollm2:1.7b (64.6 tok/s, 3GB VRAM)

3. **Sweet Spot Models:**
   - **Speed priority:** mistral:7b or llama3.1:8b (40-55 tok/s)
   - **Quality priority:** qwen2.5:32b or deepseek-r1:32b (15-25 tok/s)
   - **Balanced:** qwen2.5:14b, deepseek-r1:14b, or phi4:14b (30-40 tok/s)
   - **Best sub-70B:** mistral-small:24b (rivals Llama 3.3 70B)

4. **VRAM Efficiency:**
   - 32B is the maximum comfortable model size
   - 34B models work but leave little headroom
   - Q4 quantization essential for large models
   - MoE models (qwen3:30b-a3b, nemotron-3-nano:30b) offer 30B total with ~3.5B active

5. **Performance Patterns:**
   - GPU utilization scales with model complexity (60-97%)
   - Reasoning models show 2-3x slower speeds due to chain-of-thought
   - Vision models (qwen3-vl, gemma3) maintain competitive speeds
   - Small models have higher tokens/sec but lower quality
   - MoE models provide excellent speed-to-quality ratio
   - Temperature management crucial for sustained use

6. **Best Value by Category:**
   - **General use:** qwen2.5:14b or phi4:14b (best quality-to-resource ratio)
   - **Long context:** phi3:14b (128k), nemotron-3-nano:30b (1M context!)
   - **Coding:** qwen2.5-coder:14b (balanced), deepseek-coder:33b (best quality)
   - **Reasoning:** deepseek-r1:14b (best value), qwq:32b (advanced)
   - **Agentic AI/RAG:** nemotron-mini:4b (compact), nemotron-3-nano:30b (advanced)
   - **Vision + Function Calling:** ministral-3:8b (balanced), ministral-3:14b (advanced)

7. **2025 Highlights:**
   - **NVIDIA Nemotron 3** - Hybrid Mamba-Transformer MoE, 4x faster, 1M context
   - **Mistral Small 3** - 24B that rivals 70B models
   - **Ministral 3** - Edge-optimized with vision capabilities
   - **Phi-4** - Microsoft's latest reasoning champion
   - **QwQ** - Qwen's dedicated reasoning model

---

## 2025/2026 Model Updates

### DeepSeek-R1 Series (Reasoning Specialists)
New reasoning-focused models with chain-of-thought capabilities:
- **deepseek-r1:8b** - Fast reasoning baseline
- **deepseek-r1:14b** - Best reasoning value
- **deepseek-r1:32b** - Maximum reasoning quality

### Qwen3 Series (Next Generation)
Updated Qwen series with improved performance:
- **qwen3:8b** - Enhanced 8B baseline
- **qwen3:14b** - Better quality than qwen2.5:14b
- **qwen3:30b-a3b** - Mixture of Experts, fast for size
- **qwq:32b** - Advanced reasoning specialist

### Gemma3 Series (Multimodal)
Google's multimodal models:
- **gemma3:4b** - Compact multimodal
- **gemma3:12b** - Balanced multimodal
- **gemma3:27b** - Large multimodal

### NVIDIA Nemotron Series (Agentic AI)
NVIDIA's models optimized for agentic workflows and RAG:
- **nemotron-mini:4b** - Compact, optimized for roleplay, RAG, function calling
- **nemotron-3-nano:30b** - Hybrid Mamba-Transformer MoE (3.5B active, 31.6B total)
  - 4x faster than Nemotron 2
  - 1M token context window
  - Multilingual support (6 languages)
  - Trained from scratch by NVIDIA

### Mistral/Ministral Series Updates
New Mistral models for 2025:
- **mistral-small:24b** - Best-in-class sub-70B model (rivals Llama 3.3 70B)
  - Released January 2025
  - Apache 2.0 license
  - Multilingual (10+ languages)
- **ministral-3:3b** - Edge deployment specialist
- **ministral-3:8b** - Balanced agentic AI with vision
- **ministral-3:14b** - Advanced agentic AI with function calling
  - All Ministral models feature vision capabilities, function calling, JSON output

### Microsoft Phi Series
Latest from Microsoft:
- **phi4:14b** - State-of-the-art reasoning, rivals larger models
  - Complex reasoning capabilities
  - 9.1GB storage requirement

### Meta Llama Updates
- **llama3.3:70b** - Rivals Llama 3.1 405B performance
  - Too large for RTX 3090 (requires Q2 or multi-GPU)
  - 43GB Q4, 24GB Q2

---

## Models NOT Recommended for RTX 3090

These models will NOT run well on 24GB VRAM:

| Model | Required VRAM | Issue |
|-------|--------------|-------|
| llama3.1:70b (FP16) | 140GB+ | Won't load |
| llama3.1:70b (Q4) | 26GB+ | CPU offloading, 1-5 tok/s |
| llama3.1:70b (Q2) | ~19GB | Severe quality loss |
| qwen2.5:72b (Q4) | 36GB+ | Won't load, crashes |
| mixtral:8x7b | 28GB+ | Mixture of experts too large |

**For 70B+ models:** Consider dual RTX 3090 setup, RTX 4090, or A100/H100.

---

## Running Benchmarks

### Quick Test
```bash
./scripts/test-model.sh ollama "Your test prompt"
```

### Single Model Benchmark
```bash
./scripts/benchmark.sh ollama 10
```

### Comprehensive Automated Benchmark
```bash
# Download all test models
./scripts/pull-benchmark-models.sh

# Run full automated benchmark (34 models)
./scripts/run-full-benchmark.sh

# Results saved to benchmark_results/
```

For detailed benchmarking guide, see [Benchmark_Automation.md](Benchmark_Automation.md)

---

## Related Documentation

- **[Model_Guide.md](Model_Guide.md)** - Quick model selection guide (start here for fast decisions)
- **[Benchmark_Automation.md](Benchmark_Automation.md)** - Automated benchmarking workflow
- **[Install.md](Install.md)** - Installation walkthrough

---

**Last Updated:** January 16, 2026
**Hardware:** Dell T5820 + RTX 3090 (24GB)
**Models Tested:** 48 total (1.7B to 34B parameters)
**Date:** January 16, 2026 19:32:55 PST
**Benchmark Results:** [benchmark_20260116_193255.md](../llm-docker/benchmark_results/benchmark_20260116_193255.md)
**Methodology:** Automated comprehensive benchmark suite with 5 diverse prompts per model (simple, reasoning, coding, creative, math)

### New in January 2026
- DeepSeek-R1 series (8B, 14B, 32B) - Chain-of-thought reasoning
- Qwen3 series (8B, 14B, 30B-a3b) - 48% faster than Qwen2.5
- Qwen3-VL series (8B, 32B) - Vision + text models
- Gemma3 series (4B, 12B, 27B) - Multimodal capabilities
- EXAONE-Deep (7.8B, 32B) - LG's speed champion at 90.1 tok/s
- Marco-O1 (7B) - Fast reasoning specialist
- Falcon3 (7B, 10B) - TII's open alternative
- Aya-Expanse (8B, 32B) - Cohere's multilingual models
- GLM4 (9B) - Zhipu AI Chinese-English bilingual
- SmolLM2 (1.7B) - HuggingFace's tiny powerhouse
- OLMo2 (13B) - AI2's fully open research model

## Resources

- [Ollama Models Library](https://ollama.com/library)
- [Model_Guide.md](Model_Guide.md) - Model selection guide
- [Latest Benchmark Results](../llm-docker/benchmark_results/)
