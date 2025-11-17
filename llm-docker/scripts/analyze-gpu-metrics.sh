#!/bin/bash
# Analyze GPU metrics log and correlate with benchmark results
# Run this after benchmark completes to get accurate GPU utilization data

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/../benchmark_results"

echo "=== GPU Metrics Analyzer ==="
echo ""

# Find the most recent metrics log
METRICS_LOG=$(ls -t "$RESULTS_DIR"/gpu_metrics_*.csv 2>/dev/null | head -1)

if [ -z "$METRICS_LOG" ]; then
    echo "❌ No GPU metrics log found in $RESULTS_DIR"
    echo "Run gpu-metrics-logger.sh during benchmarking first."
    exit 1
fi

echo "Analyzing: $METRICS_LOG"
echo ""

# Find the most recent benchmark results
BENCHMARK_LOG=$(ls -t "$RESULTS_DIR"/benchmark_*.md 2>/dev/null | head -1)

if [ -z "$BENCHMARK_LOG" ]; then
    echo "⚠️  No benchmark results found. Showing overall metrics summary."
fi

# Calculate statistics from the metrics log
echo "## Overall GPU Metrics Summary"
echo ""

# Skip header line
tail -n +2 "$METRICS_LOG" | awk -F',' '
BEGIN {
    max_util = 0
    max_temp = 0
    max_power = 0
    max_vram = 0
    sum_util = 0
    sum_temp = 0
    count = 0
}
{
    util = $2
    vram = $3
    temp = $5
    power = $6
    
    if (util > max_util) max_util = util
    if (temp > max_temp) max_temp = temp
    if (power > max_power) max_power = power
    if (vram > max_vram) max_vram = vram
    
    sum_util += util
    sum_temp += temp
    count++
}
END {
    if (count > 0) {
        avg_util = sum_util / count
        avg_temp = sum_temp / count
        printf "- Peak GPU Utilization: %d%%\n", max_util
        printf "- Average GPU Utilization: %.1f%%\n", avg_util
        printf "- Peak Temperature: %d°C\n", max_temp
        printf "- Average Temperature: %.1f°C\n", avg_temp
        printf "- Peak Power Draw: %.1fW\n", max_power
        printf "- Peak VRAM Usage: %d MB (%.1f GB)\n", max_vram, max_vram/1024
        printf "- Total samples: %d (%.1f minutes)\n", count, count/60
    }
}
'

echo ""
echo "## Utilization Periods (GPU > 50%)"
echo ""

# Find periods of high GPU utilization (actual inference)
tail -n +2 "$METRICS_LOG" | awk -F',' '
BEGIN {
    in_period = 0
    period_start = ""
    period_max_util = 0
    period_max_temp = 0
    period_max_vram = 0
}
{
    timestamp = $1
    util = $2
    vram = $3
    temp = $5
    
    if (util > 50) {
        if (!in_period) {
            in_period = 1
            period_start = timestamp
            period_max_util = util
            period_max_temp = temp
            period_max_vram = vram
        } else {
            if (util > period_max_util) period_max_util = util
            if (temp > period_max_temp) period_max_temp = temp
            if (vram > period_max_vram) period_max_vram = vram
        }
    } else {
        if (in_period) {
            printf "- %s: Peak %d%% GPU, %d°C, %d MB VRAM\n", period_start, period_max_util, period_max_temp, period_max_vram
            in_period = 0
        }
    }
}
END {
    if (in_period) {
        printf "- %s: Peak %d%% GPU, %d°C, %d MB VRAM\n", period_start, period_max_util, period_max_temp, period_max_vram
    }
}
'

echo ""

# Generate a summary table by VRAM usage (model proxy)
echo "## Peak Metrics by Model Size (estimated by VRAM)"
echo ""
echo "| VRAM Range | Peak GPU Util | Peak Temp | Peak Power |"
echo "|------------|---------------|-----------|------------|"

tail -n +2 "$METRICS_LOG" | awk -F',' '
{
    util = $2
    vram = $3
    temp = $5
    power = $6
    
    # Categorize by VRAM usage
    if (vram < 3000) category = "small"
    else if (vram < 7000) category = "medium"
    else if (vram < 12000) category = "large"
    else category = "xlarge"
    
    if (util > max_util[category]) max_util[category] = util
    if (temp > max_temp[category]) max_temp[category] = temp
    if (power > max_power[category]) max_power[category] = power
}
END {
    if (max_util["small"] > 0) printf "| <3GB (3B) | %d%% | %d°C | %.0fW |\n", max_util["small"], max_temp["small"], max_power["small"]
    if (max_util["medium"] > 0) printf "| 3-7GB (7-8B) | %d%% | %d°C | %.0fW |\n", max_util["medium"], max_temp["medium"], max_power["medium"]
    if (max_util["large"] > 0) printf "| 7-12GB (14B) | %d%% | %d°C | %.0fW |\n", max_util["large"], max_temp["large"], max_power["large"]
    if (max_util["xlarge"] > 0) printf "| >12GB (27-34B) | %d%% | %d°C | %.0fW |\n", max_util["xlarge"], max_temp["xlarge"], max_power["xlarge"]
}
'

echo ""
echo "Log file: $METRICS_LOG"
echo ""
echo "Analysis complete!"