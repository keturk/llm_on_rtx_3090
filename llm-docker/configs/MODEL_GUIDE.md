# Popular Models for Testing (RTX 3090 24GB)

## Small Models (3-8B) - Fast & Efficient

### Llama 3.2 3B
- **Ollama**: `llama3.2:3b`
- **HF**: `meta-llama/Llama-3.2-3B-Instruct`
- **VRAM**: ~6 GB (FP16), ~2 GB (Q4)
- **Use**: Fast responses, good for testing

### Llama 3.1 8B
- **Ollama**: `llama3.1:8b`, `llama3.1:8b-q4`
- **HF**: `meta-llama/Llama-3.1-8B-Instruct`
- **VRAM**: ~16 GB (FP16), ~5 GB (Q4)
- **Use**: Best balance of quality/speed

### Qwen 2.5 7B
- **Ollama**: `qwen2.5:7b`
- **HF**: `Qwen/Qwen2.5-7B-Instruct`
- **VRAM**: ~14 GB (FP16), ~4 GB (Q4)
- **Use**: Strong coding & reasoning

### Phi-3 Medium (14B)
- **Ollama**: `phi3:14b`
- **HF**: `microsoft/Phi-3-medium-128k-instruct`
- **VRAM**: ~28 GB (FP16), ~8 GB (Q4)
- **Use**: Long context (128k tokens)

## Medium Models (13-30B) - Quality Focus

### Mistral 7B v0.3
- **Ollama**: `mistral:7b`
- **HF**: `mistralai/Mistral-7B-Instruct-v0.3`
- **VRAM**: ~14 GB (FP16), ~4 GB (Q4)
- **Use**: Well-rounded performance

### Gemma 2 27B
- **Ollama**: `gemma2:27b-q4`
- **HF**: `google/gemma-2-27b-it`
- **VRAM**: Too large (FP16), ~15 GB (Q4)
- **Use**: High quality responses

### Qwen 2.5 14B
- **Ollama**: `qwen2.5:14b-q4`
- **HF**: `Qwen/Qwen2.5-14B-Instruct`
- **VRAM**: ~28 GB (FP16), ~8 GB (Q4)
- **Use**: Advanced reasoning

## Large Models (70B+) - Aggressive Quantization Required

### Llama 3.1 70B
- **Ollama**: `llama3.1:70b-q2`, `llama3.1:70b-q3`
- **HF**: `meta-llama/Llama-3.1-70B-Instruct`
- **VRAM**: ~140 GB (FP16), ~19 GB (Q2), ~24 GB (Q3)
- **Use**: Maximum quality (slow)

### Qwen 2.5 72B
- **Ollama**: `qwen2.5:72b-q2`
- **HF**: `Qwen/Qwen2.5-72B-Instruct`
- **VRAM**: ~140 GB (FP16), ~19 GB (Q2)
- **Use**: Cutting-edge reasoning

## Specialized Models

### Code Llama 34B
- **Ollama**: `codellama:34b-q4`
- **HF**: `meta-llama/CodeLlama-34b-Instruct-hf`
- **VRAM**: ~68 GB (FP16), ~18 GB (Q4)
- **Use**: Code generation

### Deepseek Coder 33B
- **Ollama**: `deepseek-coder:33b-q4`
- **HF**: `deepseek-ai/deepseek-coder-33b-instruct`
- **VRAM**: ~66 GB (FP16), ~17 GB (Q4)
- **Use**: Advanced coding

## Testing Strategy

### Phase 1: Small Models (Baseline)
1. `llama3.2:3b` - Fast baseline
2. `llama3.1:8b` - Quality baseline
3. `qwen2.5:7b` - Coding test

### Phase 2: Quantization Comparison
Compare same model at different quants:
1. `llama3.1:8b` (full precision)
2. `llama3.1:8b-q4` (4-bit)
3. `llama3.1:8b-q2` (2-bit)

### Phase 3: Size Scaling
Test larger models with Q4:
1. `phi3:14b-q4`
2. `qwen2.5:14b-q4`
3. `gemma2:27b-q4`

### Phase 4: Maximum Quality
Test 70B models with aggressive quantization:
1. `llama3.1:70b-q2`
2. `llama3.1:70b-q3` (if fits)
3. `qwen2.5:72b-q2`

## Quantization Quality Guide

| Quant | Quality Loss | Speed Gain | VRAM Savings |
|-------|--------------|------------|--------------|
| FP16  | 0% (baseline)| 1x         | 1x           |
| Q8    | <1%          | 1.2x       | 2x           |
| Q6    | ~1%          | 1.3x       | 2.7x         |
| Q5    | ~2%          | 1.4x       | 3.2x         |
| Q4    | ~3-5%        | 1.5x       | 4x           |
| Q3    | ~8-10%       | 1.6x       | 5.3x         |
| Q2    | ~15-20%      | 1.7x       | 8x           |

## Notes
- Q4 is the sweet spot for most use cases
- Q2/Q3 only for when you need to fit large models
- For 24GB VRAM, Q4 lets you run ~30B models
- Full precision (FP16) limited to 8-13B models
