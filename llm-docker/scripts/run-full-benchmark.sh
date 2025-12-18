#!/bin/bash
# Automated Full Benchmark Suite
# Runs the complete benchmark workflow in a single command
# Updated December 2025 - Includes DeepSeek-R1, Qwen3, Gemma3

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/../benchmark_results"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line options
SKIP_PULL=false
SKIP_GPU_LOGGER=false
AUTO_YES=false

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-pull          Skip downloading models (use only installed models)"
    echo "  --skip-gpu-logger    Skip GPU metrics logging"
    echo "  -y, --yes            Auto-confirm all prompts"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Example:"
    echo "  $0                   # Full benchmark with all prompts"
    echo "  $0 --skip-pull -y    # Quick benchmark with installed models only"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-pull)
            SKIP_PULL=true
            shift
            ;;
        --skip-gpu-logger)
            SKIP_GPU_LOGGER=true
            shift
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Automated LLM Benchmark Suite - RTX 3090${NC}"
echo -e "${BLUE}   December 2025 Edition${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Check if Ollama is running, start if needed
echo -e "${YELLOW}[Step 1/5] Checking Ollama service...${NC}"
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "Ollama is not running. Starting Ollama..."
    "${SCRIPT_DIR}/start-ollama.sh"
    sleep 3
else
    echo -e "${GREEN}✅ Ollama is already running${NC}"
fi
echo ""

# Step 2: Download benchmark models (if not skipped)
if [ "$SKIP_PULL" = false ]; then
    echo -e "${YELLOW}[Step 2/5] Checking benchmark models...${NC}"

    # Check how many models are installed
    INSTALLED_COUNT=$(docker exec ollama ollama list 2>/dev/null | grep -E "llama3|mistral|qwen|deepseek|gemma|phi|codellama|nemotron|ministral|qwq|granite|dolphin|codestral" | wc -l)
    TOTAL_MODELS=34

    echo "Installed models: $INSTALLED_COUNT/$TOTAL_MODELS"

    if [ $INSTALLED_COUNT -lt $TOTAL_MODELS ]; then
        echo "Some benchmark models are missing."

        if [ "$AUTO_YES" = false ]; then
            read -p "Download missing models? This may take a while. (y/N) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Skipping model download. Will benchmark installed models only."
            else
                "${SCRIPT_DIR}/pull-benchmark-models.sh"
            fi
        else
            echo "Auto-yes mode: Skipping model download prompt."
            echo "Will benchmark installed models only."
        fi
    else
        echo -e "${GREEN}✅ All benchmark models are installed${NC}"
    fi
else
    echo -e "${YELLOW}[Step 2/5] Skipping model download (--skip-pull)${NC}"
fi
echo ""

# Step 3: Start GPU metrics logger in background (if not skipped)
GPU_LOGGER_PID=""
if [ "$SKIP_GPU_LOGGER" = false ]; then
    echo -e "${YELLOW}[Step 3/5] Starting GPU metrics logger...${NC}"

    # Start GPU logger in background (redirect output to avoid console clutter)
    "${SCRIPT_DIR}/gpu-metrics-logger.sh" > /dev/null 2>&1 &
    GPU_LOGGER_PID=$!

    # Give it a moment to start
    sleep 2

    # Check if it's running
    if ps -p $GPU_LOGGER_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ GPU metrics logger started (PID: $GPU_LOGGER_PID)${NC}"
        echo "   Logging GPU utilization, memory, temperature, and power"
    else
        echo -e "${RED}⚠️  GPU metrics logger failed to start${NC}"
        GPU_LOGGER_PID=""
    fi
else
    echo -e "${YELLOW}[Step 3/5] Skipping GPU metrics logger (--skip-gpu-logger)${NC}"
fi
echo ""

# Step 4: Run comprehensive benchmark
echo -e "${YELLOW}[Step 4/5] Running comprehensive benchmark...${NC}"
echo "This will test all installed models with multiple prompts."
echo "Estimated time: 5-10 minutes per model"
echo ""

if [ "$AUTO_YES" = false ]; then
    read -p "Start benchmark now? (Y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Benchmark cancelled."
        # Kill GPU logger if running
        if [ -n "$GPU_LOGGER_PID" ]; then
            kill $GPU_LOGGER_PID 2>/dev/null || true
        fi
        exit 0
    fi
fi

echo ""
echo -e "${GREEN}Starting benchmark...${NC}"
echo ""

# Run the benchmark
"${SCRIPT_DIR}/comprehensive-benchmark.sh"

BENCHMARK_EXIT_CODE=$?
echo ""

# Step 5: Stop GPU logger and analyze metrics
if [ -n "$GPU_LOGGER_PID" ]; then
    echo -e "${YELLOW}[Step 5/5] Stopping GPU metrics logger and analyzing...${NC}"

    # Stop the logger and all its child processes
    pkill -P $GPU_LOGGER_PID 2>/dev/null || true
    kill $GPU_LOGGER_PID 2>/dev/null || true
    wait $GPU_LOGGER_PID 2>/dev/null || true

    echo -e "${GREEN}✅ GPU metrics logger stopped${NC}"
    sleep 1

    # Analyze GPU metrics
    if [ -f "${SCRIPT_DIR}/analyze-gpu-metrics.sh" ]; then
        echo ""
        echo "Analyzing GPU metrics..."
        "${SCRIPT_DIR}/analyze-gpu-metrics.sh"
    fi
else
    echo -e "${YELLOW}[Step 5/5] No GPU metrics to analyze${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Benchmark Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

if [ $BENCHMARK_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Benchmark completed successfully${NC}"
    echo ""
    echo "Results saved to:"
    echo "  📊 Latest benchmark: $(ls -t ${RESULTS_DIR}/benchmark_*.md 2>/dev/null | head -1)"
    echo "  📈 README table: $(ls -t ${RESULTS_DIR}/readme_table_*.md 2>/dev/null | head -1)"

    if [ "$SKIP_GPU_LOGGER" = false ]; then
        echo "  🎯 GPU metrics: $(ls -t ${RESULTS_DIR}/gpu_metrics_*.csv 2>/dev/null | head -1)"
    fi

    echo ""
    echo "Next steps:"
    echo "  • View results: cat $(ls -t ${RESULTS_DIR}/benchmark_*.md 2>/dev/null | head -1)"
    echo "  • Update README: Copy table from $(ls -t ${RESULTS_DIR}/readme_table_*.md 2>/dev/null | head -1)"
else
    echo -e "${RED}❌ Benchmark encountered errors${NC}"
    echo "Check the output above for details."
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
