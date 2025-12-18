# Automated Benchmark Suite

## Quick Start

Run the complete benchmark suite with a single command:

```bash
./scripts/run-full-benchmark.sh
```

This automated script handles everything:
1. ✅ Starts Ollama service (if not running)
2. 📥 Downloads missing benchmark models (optional)
3. 📊 Starts GPU metrics logging
4. 🚀 Runs comprehensive benchmarks
5. 📈 Analyzes results and generates reports

## What It Does

### Automated Steps

| Step | Action | Details |
|------|--------|---------|
| **1. Service Check** | Verifies Ollama is running | Automatically starts if needed |
| **2. Model Download** | Checks for 20 benchmark models | Prompts to download missing models |
| **3. GPU Logging** | Starts background metrics logger | Tracks utilization, VRAM, temp, power |
| **4. Benchmark** | Tests all installed models | Multiple prompts per model |
| **5. Analysis** | Analyzes GPU metrics | Generates comprehensive reports |

### Time Estimates

- **Quick run** (installed models only): 30-60 minutes
- **Full run** (all 34 models): 3-5 hours
- **Model downloads** (if needed): 60-120 minutes (depends on bandwidth)

## Command Options

### Basic Usage

```bash
# Full benchmark with all prompts
./scripts/run-full-benchmark.sh

# Skip model downloads (use only installed models)
./scripts/run-full-benchmark.sh --skip-pull

# Skip GPU metrics logging
./scripts/run-full-benchmark.sh --skip-gpu-logger

# Auto-confirm all prompts (non-interactive)
./scripts/run-full-benchmark.sh -y

# Combine options
./scripts/run-full-benchmark.sh --skip-pull -y
```

### Options Reference

| Option | Description |
|--------|-------------|
| `--skip-pull` | Skip model downloads, benchmark installed models only |
| `--skip-gpu-logger` | Don't log GPU metrics (faster but less detailed) |
| `-y, --yes` | Auto-confirm all prompts (useful for automation) |
| `-h, --help` | Show help message |

## Output Files

All results are saved to `benchmark_results/` with timestamps:

### Generated Files

1. **benchmark_YYYYMMDD_HHMMSS.md**
   - Complete benchmark results
   - Performance metrics per model
   - Detailed prompt analysis
   - Recommendations by use case

2. **benchmark_YYYYMMDD_HHMMSS.md.timing**
   - Timestamp markers for each model test
   - Used to correlate with GPU metrics

3. **readme_table_YYYYMMDD_HHMMSS.md**
   - Ready-to-paste markdown table
   - Summary of all models tested
   - Perfect for updating README.md

4. **gpu_metrics_YYYYMMDD_HHMMSS.csv**
   - Second-by-second GPU data
   - Columns: timestamp, GPU%, VRAM MB, temp °C, power W
   - Used for detailed performance analysis

## Comparison: Manual vs Automated

### Manual Process (Old Way)

```bash
# 1. Start Ollama
./scripts/start-ollama.sh

# 2. Download models (in another terminal)
./scripts/pull-benchmark-models.sh

# 3. Start GPU logger (in another terminal)
./scripts/gpu-metrics-logger.sh

# 4. Run benchmark (in original terminal)
./scripts/comprehensive-benchmark.sh

# 5. Wait for completion, then stop GPU logger (Ctrl+C)

# 6. Analyze GPU metrics
./scripts/analyze-gpu-metrics.sh
```

**Problems:**
- Requires 2-3 terminal windows
- Easy to forget steps
- Manual coordination needed
- Must remember to stop GPU logger

### Automated Process (New Way)

```bash
./scripts/run-full-benchmark.sh
```

**Benefits:**
- Single command
- One terminal window
- Automatic coordination
- Automatic cleanup
- Cannot forget steps

## Example Workflows

### Full Benchmark (First Time)

```bash
# Download all models and run complete benchmark
./scripts/run-full-benchmark.sh
```

**What happens:**
1. Checks Ollama (starts if needed)
2. Shows 34 models, prompts to download missing ones
3. Starts GPU logger in background
4. Runs benchmark on all models
5. Stops logger and analyzes metrics
6. Saves all results

### Quick Re-test (Models Already Installed)

```bash
# Skip downloads, just benchmark
./scripts/run-full-benchmark.sh --skip-pull -y
```

**What happens:**
1. Checks Ollama
2. Skips model check
3. Starts GPU logger
4. Runs benchmark
5. Analyzes and saves results

### Minimal Benchmark (No GPU Metrics)

```bash
# Fastest option - benchmark only
./scripts/run-full-benchmark.sh --skip-pull --skip-gpu-logger -y
```

**What happens:**
1. Checks Ollama
2. Runs benchmark immediately
3. Saves basic results (no GPU correlation)

### CI/CD Integration

```bash
# Fully automated for scripts
./scripts/run-full-benchmark.sh --skip-pull --skip-gpu-logger -y
```

## Viewing Results

### Quick Summary

```bash
# View latest benchmark results
cat $(ls -t benchmark_results/benchmark_*.md | head -1)
```

### README Table

```bash
# View table ready for README.md
cat $(ls -t benchmark_results/readme_table_*.md | head -1)
```

### GPU Metrics

```bash
# View GPU metrics CSV
cat $(ls -t benchmark_results/gpu_metrics_*.csv | head -1)
```

### All Results

```bash
# List all results
ls -lth benchmark_results/
```

## Troubleshooting

### Ollama Won't Start

```bash
# Check Docker status
docker ps

# View Ollama logs
docker compose logs ollama

# Restart Ollama manually
./scripts/stop-all.sh
./scripts/start-ollama.sh
```

### GPU Logger Fails

Ensure NVIDIA drivers and `nvidia-smi` are available:

```bash
nvidia-smi
```

If GPU logger fails, you can skip it:

```bash
./scripts/run-full-benchmark.sh --skip-gpu-logger
```

### Out of Disk Space

Check available space:

```bash
df -h

# View model storage
docker exec ollama du -sh /root/.ollama/models
```

Remove unused models:

```bash
docker exec ollama ollama rm <model-name>
```

### Benchmark Takes Too Long

Test fewer models by editing `comprehensive-benchmark.sh`:

```bash
# Comment out models you don't want to test
nano scripts/comprehensive-benchmark.sh
```

Or use the quick benchmark instead:

```bash
./scripts/benchmark.sh ollama 5
```

## Advanced Usage

### Testing Specific Model Categories

Edit `comprehensive-benchmark.sh` to comment out model categories:

```bash
MODELS=(
    # === Small Models (3-8B) - Fast ===
    "llama3.2:3b"
    # ... keep these

    # === Medium Models (12-14B) - Balanced ===
    # "phi3:14b"          # Comment out to skip
    # "qwen2.5:14b"       # Comment out to skip
    # ...
)
```

### Custom Prompts

Edit the PROMPTS array in `comprehensive-benchmark.sh`:

```bash
declare -A PROMPTS
PROMPTS["simple"]="Your custom simple prompt"
PROMPTS["reasoning"]="Your custom reasoning prompt"
# ... etc
```

### Scheduling Automated Runs

Use cron for scheduled benchmarks:

```bash
# Run benchmark every Sunday at 2am
0 2 * * 0 cd /home/llmuser/llm_on_rtx_3090/llm-docker && ./scripts/run-full-benchmark.sh -y >> /var/log/llm-benchmark.log 2>&1
```

## Related Scripts

All individual scripts are still available for manual use:

| Script | Purpose | Use When |
|--------|---------|----------|
| `start-ollama.sh` | Start Ollama service | Manual service control |
| `pull-benchmark-models.sh` | Download models | Need specific models |
| `gpu-metrics-logger.sh` | Log GPU metrics | Want to monitor GPU manually |
| `comprehensive-benchmark.sh` | Run benchmarks | Want manual benchmark control |
| `analyze-gpu-metrics.sh` | Analyze GPU data | Post-process existing logs |
| `benchmark.sh` | Quick single-model test | Test one specific model |

## Summary

The automated script combines all manual steps into one streamlined workflow, making it easy to run comprehensive benchmarks without managing multiple terminals or remembering complex sequences.

**One command. Complete results.**

```bash
./scripts/run-full-benchmark.sh
```
