#!/bin/bash
# Native Ollama benchmark for the ASUS GX10 (GB10, ARM) — no Docker.
#
# Measures ACCURATE generation speed via `ollama run --verbose` (parses the reported
# `eval rate`, which excludes model load time), unlike the crude words×1.3/wall-clock
# estimate used by the T5820 Docker benchmark.
#
# Default set ("compare") is exactly the models with known RTX 3090 numbers, so results
# line up head-to-head with the Dell T5820 in docs/machines/gx10/Benchmarks.md.
#
# Usage:
#   scripts/benchmark-native.sh [set] [--pull] [-y]
#     set     compare (default) | big | all | <space-separated models via MODELS=...>
#     --pull  download any missing models before benchmarking
#     -y      don't prompt (auto-confirm pulls)
#     --list  print the model sets and exit

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="${REPO_DIR}/benchmark_results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# --- model sets -------------------------------------------------------------
# "compare": fits on a 24 GB RTX 3090 AND has a recorded T5820 number (see RTX3090[] below).
COMPARE_MODELS=(
    llama3.2:3b llama3.1:8b mistral:7b qwen2.5:7b
    phi3:14b qwen2.5:14b
    gemma2:27b qwen2.5:32b codellama:34b deepseek-coder:33b
)
# "big": too large for a 24 GB card — the reason the GX10 exists (unified memory).
BIG_MODELS=(
    nemotron-3-nano:30b
    nemotron-3-super:120b
)

# --- RTX 3090 reference (tokens/sec, reasoning prompt) -----------------------
# Source: latest T5820 run, llm-docker/benchmark_results/readme_table_*.md
declare -A RTX3090=(
    [llama3.2:3b]=48.3 [llama3.1:8b]=47.1 [mistral:7b]=65.3 [qwen2.5:7b]=30.5
    [phi3:14b]=31.7 [qwen2.5:14b]=25.1
    [gemma2:27b]=20.8 [qwen2.5:32b]=20.2 [codellama:34b]=22.4 [deepseek-coder:33b]=19.9
)

# --- primary prompt (matches the T5820 "reasoning" metric) ------------------
PROMPT="Explain the difference between supervised and unsupervised machine learning in 3 sentences"

# --- args -------------------------------------------------------------------
SET="compare"; DO_PULL=0; ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --pull) DO_PULL=1 ;;
        -y|--yes) ASSUME_YES=1 ;;
        --list)
            echo "compare : ${COMPARE_MODELS[*]}"
            echo "big     : ${BIG_MODELS[*]}"
            echo "all     : compare + big"
            exit 0 ;;
        -h|--help)
            sed -n '2,20p' "$0"; exit 0 ;;
        -*) echo "Unknown option: $arg" >&2; exit 1 ;;
        *) SET="$arg" ;;
    esac
done

case "$SET" in
    compare) MODELS=("${COMPARE_MODELS[@]}") ;;
    big)     MODELS=("${BIG_MODELS[@]}") ;;
    all)     MODELS=("${COMPARE_MODELS[@]}" "${BIG_MODELS[@]}") ;;
    *)       read -r -a MODELS <<<"$SET" ;;   # treat as literal model list
esac

# --- preflight --------------------------------------------------------------
if ! command -v ollama >/dev/null 2>&1; then
    echo "❌ ollama not found. This script is for the GX10's native Ollama." >&2
    exit 1
fi
# If the default client endpoint is dead, fall back to the native server port.
if ! ollama list >/dev/null 2>&1; then
    export OLLAMA_HOST="127.0.0.1:11500"
fi
if ! ollama list >/dev/null 2>&1; then
    echo "❌ Cannot reach the Ollama server (tried default and :11500)." >&2
    echo "   Start it: sudo systemctl start ollama" >&2
    exit 1
fi

[ "$(uname -m)" = "aarch64" ] || echo "⚠️  Not aarch64 — this script targets the GX10; running anyway."

mkdir -p "$RESULTS_DIR"
RESULTS_FILE="${RESULTS_DIR}/gx10_benchmark_${TIMESTAMP}.md"

installed_list="$(ollama list 2>/dev/null)"
is_installed() { grep -qE "^$1([[:space:]]|:latest)" <<<"$installed_list"; }

# --- pull missing (optional) ------------------------------------------------
missing=()
for m in "${MODELS[@]}"; do is_installed "$m" || missing+=("$m"); done
if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing models (${#missing[@]}): ${missing[*]}"
    if [ "$DO_PULL" -eq 1 ]; then
        if [ "$ASSUME_YES" -ne 1 ]; then
            read -rp "Pull ${#missing[@]} missing models now? (y/N) " a; [[ "$a" =~ ^[Yy]$ ]] || DO_PULL=0
        fi
    fi
    if [ "$DO_PULL" -eq 1 ]; then
        for m in "${missing[@]}"; do echo "📥 pulling $m…"; ollama pull "$m"; done
        installed_list="$(ollama list 2>/dev/null)"
    else
        echo "   (skipping missing models — rerun with --pull to download them)"
    fi
fi

# --- measure one model ------------------------------------------------------
# Warms up (loads into unified memory), then measures the reasoning prompt.
# Returns: "<eval_rate>|<eval_count>|<size>"  (rate empty on failure)
bench_one() {
    local model="$1" out clean rate count size
    ollama run "$model" "hi" >/dev/null 2>&1        # warm-up (excludes load from the timed run)
    out="$(ollama run --verbose "$model" "$PROMPT" 2>&1)"
    clean="$(tr -d '\r' <<<"$out")"
    rate="$(awk '/eval rate:/ && !/prompt eval rate/ {print $(NF-1)}' <<<"$clean" | head -1)"
    count="$(awk '/eval count:/ && !/prompt eval count/ {print $3}' <<<"$clean" | head -1)"
    size="$(grep -E "^${model}([[:space:]]|:latest)" <<<"$installed_list" | head -1 | awk '{print $3$4}')"
    ollama stop "$model" >/dev/null 2>&1 || true    # free memory before the next model
    printf '%s|%s|%s' "$rate" "$count" "$size"
}

# --- run --------------------------------------------------------------------
{
    echo "# GX10 Native Benchmark — ${TIMESTAMP}"
    echo
    echo "System: ASUS GX10 (NVIDIA GB10, ARM aarch64) · native Ollama · $(ollama --version 2>/dev/null | head -1)"
    echo "Metric: \`ollama --verbose\` **eval rate** (generation tokens/sec, load time excluded)"
    echo "Prompt: \"$PROMPT\""
    echo
    echo "| Model | Size | GX10 tok/s | RTX 3090 tok/s | Δ (GX10−3090) | Fits 3090? |"
    echo "|-------|------|-----------:|---------------:|--------------:|:----------:|"
} | tee "$RESULTS_FILE"

for model in "${MODELS[@]}"; do
    if ! is_installed "$model"; then
        printf '| %s | — | _not installed_ | %s | — | — |\n' \
            "$model" "${RTX3090[$model]:-—}" | tee -a "$RESULTS_FILE"
        continue
    fi
    echo "→ benchmarking $model …" >&2
    res="$(bench_one "$model")"
    rate="${res%%|*}"; rest="${res#*|}"; count="${rest%%|*}"; size="${rest##*|}"
    ref="${RTX3090[$model]:-}"
    fits="✅"; [[ " ${BIG_MODELS[*]} " == *" $model "* ]] && fits="❌"
    if [ -n "$rate" ] && [ -n "$ref" ]; then
        delta="$(awk -v a="$rate" -v b="$ref" 'BEGIN{printf "%+.1f", a-b}')"
    else
        delta="—"
    fi
    printf '| %s | %s | %s | %s | %s | %s |\n' \
        "$model" "${size:-—}" "${rate:-_failed_}" "${ref:-—}" "$delta" "$fits" \
        | tee -a "$RESULTS_FILE"
done

echo | tee -a "$RESULTS_FILE"
echo "_RTX 3090 numbers: T5820 reference (reasoning prompt). GX10 uses accurate eval-rate;" \
     "the 3090 column used words×1.3/wall-clock, so treat small gaps as noise — see Benchmarks.md._" \
     | tee -a "$RESULTS_FILE"
echo
echo "✅ Saved: $RESULTS_FILE"
