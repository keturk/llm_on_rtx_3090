#!/bin/bash
# GPU Metrics Logger - Run this in a separate terminal during benchmarks
# Logs GPU utilization, temperature, power, and VRAM with timestamps

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/../benchmark_results"
LOG_FILE="${RESULTS_DIR}/gpu_metrics_$(date +%Y%m%d_%H%M%S).csv"

mkdir -p "$RESULTS_DIR"

echo "=== GPU Metrics Logger ==="
echo "Logging to: $LOG_FILE"
echo "Press Ctrl+C to stop"
echo ""

# Create CSV header
echo "timestamp,gpu_util_pct,memory_used_mb,memory_total_mb,temperature_c,power_draw_w,power_limit_w" > "$LOG_FILE"

# Log metrics every second
while true; do
    timestamp=$(date +%Y-%m-%d_%H:%M:%S)
    
    # Get all metrics in one nvidia-smi call
    metrics=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,power.limit \
        --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')
    
    if [ -n "$metrics" ]; then
        echo "$timestamp,$metrics" >> "$LOG_FILE"
        
        # Also display current values
        gpu_util=$(echo "$metrics" | cut -d',' -f1)
        mem_used=$(echo "$metrics" | cut -d',' -f2)
        mem_total=$(echo "$metrics" | cut -d',' -f3)
        temp=$(echo "$metrics" | cut -d',' -f4)
        power=$(echo "$metrics" | cut -d',' -f5)
        
        printf "\r[%s] GPU: %3s%% | VRAM: %5s/%5s MB | Temp: %2s°C | Power: %6sW" \
            "$timestamp" "$gpu_util" "$mem_used" "$mem_total" "$temp" "$power"
    fi
    
    sleep 1
done