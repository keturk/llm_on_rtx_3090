#!/bin/bash
# Cross-machine Ollama benchmark — ACCURATE and IDENTICAL on both machines.
#
# Measures generation speed via `ollama run --verbose` (`eval rate`, which excludes model
# load time). Auto-detects the runtime so the SAME code/method runs on either machine:
#   - Dell T5820  : Ollama in a Docker container -> `docker exec <name> ollama …`
#   - ASUS GX10   : native Ollama                -> `ollama …`
#
# Use this on BOTH machines so the numbers are apples-to-apples for a fair comparison.
# (The GX10-only scripts/benchmark-native.sh is equivalent for native runs.)
#
# Usage:
#   scripts/benchmark.sh [set] [--pull] [-y]
#     set     compare (default) | big | all | "<space-separated models>"
#     --pull  download missing models first
#     -y      auto-confirm pulls
#     --list  print the sets and exit

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="${REPO_DIR}/benchmark_results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# --- model sets (must match benchmark-native.sh) ----------------------------
COMPARE_MODELS=(
    llama3.2:3b llama3.1:8b mistral:7b qwen2.5:7b
    phi3:14b qwen2.5:14b
    gemma2:27b qwen2.5:32b codellama:34b deepseek-coder:33b
)
BIG_MODELS=( nemotron-3-nano:30b nemotron-3-super:120b )
# "full": the complete cross-machine suite — already-installed first (fast rows land early),
# then everything the RTX 3090 ran but the GX10 lacked (downloaded on demand).
FULL_MODELS=(
    # --- typically already present ---
    llama3.2:3b llama3.1:8b mistral:7b qwen2.5:7b phi3:14b qwen2.5:14b
    gemma2:27b qwen2.5:32b codellama:34b deepseek-coder:33b
    nemotron-3-nano:30b nemotron-3-super:120b
    # --- rest of the suite ---
    smollm2:1.7b granite3.1-moe:3b granite3-dense:8b nemotron-mini:4b
    ministral-3:3b ministral-3:8b ministral-3:14b phi3.5 phi4-mini phi4
    qwen3:8b qwen3:14b qwen3:30b-a3b qwen3-coder:30b qwen3-vl:8b qwen3-vl:32b
    deepseek-r1:8b deepseek-r1:14b deepseek-r1:32b
    gemma3:4b gemma3:12b gemma3:27b glm4:9b
    falcon3:7b falcon3:10b hermes3:8b marco-o1:7b dolphin3 olmo2:13b
    exaone-deep:7.8b exaone-deep:32b aya-expanse:8b aya-expanse:32b
    codestral:22b mistral-small:24b qwen2.5-coder:14b qwq:32b
)

PROMPT="Explain the difference between supervised and unsupervised machine learning in 3 sentences"

# --- args -------------------------------------------------------------------
SET="compare"; DO_PULL=0; ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --pull) DO_PULL=1 ;;
        -y|--yes) ASSUME_YES=1 ;;
        --list) echo "compare : ${COMPARE_MODELS[*]}"; echo "big     : ${BIG_MODELS[*]}"; echo "all     : compare + big"; echo "full    : ${#FULL_MODELS[@]} models (complete cross-machine suite)"; exit 0 ;;
        -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
        -*) echo "Unknown option: $arg" >&2; exit 1 ;;
        *) SET="$arg" ;;
    esac
done
case "$SET" in
    compare) MODELS=("${COMPARE_MODELS[@]}") ;;
    big)     MODELS=("${BIG_MODELS[@]}") ;;
    all)     MODELS=("${COMPARE_MODELS[@]}" "${BIG_MODELS[@]}") ;;
    full)    MODELS=("${FULL_MODELS[@]}") ;;
    *)       read -r -a MODELS <<<"$SET" ;;
esac

# --- detect runtime ---------------------------------------------------------
RUNNER=(); RUNTIME=""; MACHINE=""
if command -v docker >/dev/null 2>&1; then
    CNAME="$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i ollama | head -1)"
    if [ -n "${CNAME:-}" ]; then RUNNER=(docker exec "$CNAME" ollama); RUNTIME="docker:$CNAME"; fi
fi
if [ "${#RUNNER[@]}" -eq 0 ] && command -v ollama >/dev/null 2>&1; then
    RUNNER=(ollama); RUNTIME="native"
    if ! ollama list >/dev/null 2>&1; then export OLLAMA_HOST="127.0.0.1:11500"; fi
fi
if [ "${#RUNNER[@]}" -eq 0 ]; then
    echo "❌ No Ollama runtime found (no docker 'ollama' container, no native ollama)." >&2
    exit 1
fi

ARCH="$(uname -m)"
case "$ARCH:$RUNTIME" in
    x86_64:docker*)  MACHINE="T5820 (RTX 3090, x86 / Docker)"; TAG="t5820" ;;
    aarch64:native)  MACHINE="GX10 (GB10, ARM / native)";      TAG="gx10"  ;;
    *)               MACHINE="$ARCH / $RUNTIME";                TAG="$ARCH" ;;
esac

if ! "${RUNNER[@]}" list >/dev/null 2>&1; then
    echo "❌ Cannot reach Ollama via: ${RUNNER[*]}" >&2; exit 1
fi

mkdir -p "$RESULTS_DIR"
RESULTS_FILE="${RESULTS_DIR}/${TAG}_benchmark_${TIMESTAMP}.md"
installed_list="$("${RUNNER[@]}" list 2>/dev/null)"
is_installed() { grep -qE "^$1([[:space:]]|:latest)" <<<"$installed_list"; }

# --- optional confirm before pulling (pulls happen per-model in the run loop) ---
if [ "$DO_PULL" -eq 1 ] && [ "$ASSUME_YES" -ne 1 ]; then
    miss=0; for m in "${MODELS[@]}"; do is_installed "$m" || miss=$((miss+1)); done
    if [ "$miss" -gt 0 ]; then
        read -rp "Pull $miss missing model(s) as the run proceeds? (y/N) " a
        [[ "$a" =~ ^[Yy]$ ]] || DO_PULL=0
    fi
fi

# --- measure one model ------------------------------------------------------
bench_one() {
    local model="$1" out clean rate count size
    "${RUNNER[@]}" run "$model" "hi" >/dev/null 2>&1                 # warm-up (load excluded)
    out="$("${RUNNER[@]}" run --verbose "$model" "$PROMPT" 2>&1)"
    clean="$(tr -d '\r' <<<"$out")"
    rate="$(awk '/eval rate:/ && !/prompt eval rate/ {print $(NF-1)}' <<<"$clean" | head -1)"
    count="$(awk '/eval count:/ && !/prompt eval count/ {print $3}' <<<"$clean" | head -1)"
    size="$(grep -E "^${model}([[:space:]]|:latest)" <<<"$installed_list" | head -1 | awk '{print $3$4}')"
    "${RUNNER[@]}" stop "$model" >/dev/null 2>&1 || true
    printf '%s|%s|%s' "$rate" "$count" "$size"
}

# --- run --------------------------------------------------------------------
{
    echo "# Benchmark — ${MACHINE} — ${TIMESTAMP}"
    echo
    echo "Runtime: \`${RUNNER[*]}\` · $("${RUNNER[@]}" --version 2>/dev/null | head -1)"
    echo "Metric: \`ollama --verbose\` **eval rate** (generation tok/s, load excluded)"
    echo "Prompt: \"$PROMPT\""
    echo
    echo "| Model | Size | tok/s | tokens |"
    echo "|-------|------|------:|-------:|"
} | tee "$RESULTS_FILE"

for model in "${MODELS[@]}"; do
    if ! is_installed "$model"; then
        if [ "$DO_PULL" -eq 1 ]; then
            echo "📥 pulling $model …" >&2
            if ! "${RUNNER[@]}" pull "$model" >/dev/null 2>&1; then
                printf '| %s | — | _pull failed_ | — |\n' "$model" | tee -a "$RESULTS_FILE"; continue
            fi
            installed_list="$("${RUNNER[@]}" list 2>/dev/null)"
        else
            printf '| %s | — | _not installed_ | — |\n' "$model" | tee -a "$RESULTS_FILE"; continue
        fi
    fi
    echo "→ $model …" >&2
    res="$(bench_one "$model")"; rate="${res%%|*}"; rest="${res#*|}"; count="${rest%%|*}"; size="${rest##*|}"
    printf '| %s | %s | %s | %s |\n' "$model" "${size:-—}" "${rate:-_failed_}" "${count:-—}" | tee -a "$RESULTS_FILE"
done

echo | tee -a "$RESULTS_FILE"
echo "✅ Saved: $RESULTS_FILE"
echo "   Merge this with the other machine's file for the comparison table." >&2
