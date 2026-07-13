#!/bin/bash
# ============================================================================
# Ollama GPU Monitor - Real-time monitoring for LLM inference
# System: Dell Precision T5820 / RTX 3090 24GB / Ubuntu 24.04
# Usage:  ~/ollama-monitor.sh [--once] [--unload] [--logs]
# ============================================================================

set -euo pipefail

# --- Configuration ---
OLLAMA_API="http://localhost:11434"
REFRESH_INTERVAL=2
BOLD="\033[1m"
DIM="\033[2m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
WHITE="\033[97m"
RESET="\033[0m"
BAR_WIDTH=40

# --- Helper Functions ---
draw_bar() {
    local pct=${1:-0}
    local color=$2
    local filled=$(( pct * BAR_WIDTH / 100 ))
    local empty=$(( BAR_WIDTH - filled ))
    printf "${color}"
    printf '█%.0s' $(seq 1 $filled 2>/dev/null) || true
    printf "${DIM}"
    printf '░%.0s' $(seq 1 $empty 2>/dev/null) || true
    printf "${RESET}"
}

separator() {
    printf "${DIM}──────────────────────────────────────────────────────────────${RESET}\n"
}

check_ollama_api() {
    curl -s --max-time 2 "${OLLAMA_API}/api/tags" > /dev/null 2>&1
}

# --- Unload Command ---
if [[ "${1:-}" == "--unload" ]]; then
    echo -e "${YELLOW}⏏  Unloading all models from GPU...${RESET}"
    
    # Get loaded models
    loaded=$(curl -s --max-time 5 "${OLLAMA_API}/api/ps" 2>/dev/null)
    if echo "$loaded" | python3 -c "
import sys, json
data = json.load(sys.stdin)
models = data.get('models', [])
if not models:
    print('No models loaded.')
    sys.exit(0)
for m in models:
    print(m['name'])
" 2>/dev/null; then
        # Force unload each model
        for model in $(echo "$loaded" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data.get('models', []):
    print(m['name'])
" 2>/dev/null); do
            echo -e "  Unloading ${CYAN}${model}${RESET}..."
            curl -s "${OLLAMA_API}/api/generate" \
                -d "{\"model\": \"${model}\", \"keep_alive\": 0}" > /dev/null 2>&1
        done
        echo -e "${GREEN}✓ All models unloaded.${RESET}"
    fi
    exit 0
fi

# --- Logs Command ---
if [[ "${1:-}" == "--logs" ]]; then
    echo -e "${CYAN}📋 Ollama container logs (last 50 lines, following)...${RESET}"
    separator
    docker logs -f ollama --tail 50
    exit 0
fi

# --- Main Monitor ---
show_status() {
    clear
    local now=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Header
    echo -e "${BOLD}${WHITE}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║           🖥  OLLAMA GPU MONITOR  -  llm01              ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${DIM}${now}  •  Refresh: ${REFRESH_INTERVAL}s  •  Ctrl+C to exit${RESET}"
    echo ""

    # ── GPU Status ──
    local gpu_info
    gpu_info=$(nvidia-smi --query-gpu=name,temperature.gpu,power.draw,power.limit,memory.used,memory.total,utilization.gpu,fan.speed --format=csv,noheader,nounits 2>/dev/null)
    
    if [[ -z "$gpu_info" ]]; then
        echo -e "  ${RED}✗ nvidia-smi not available${RESET}"
        return
    fi

    IFS=',' read -r gpu_name gpu_temp gpu_power gpu_power_max gpu_mem_used gpu_mem_total gpu_util fan_speed <<< "$gpu_info"
    
    # Trim whitespace
    gpu_name=$(echo "$gpu_name" | xargs)
    gpu_temp=$(echo "$gpu_temp" | xargs)
    gpu_power=$(echo "$gpu_power" | xargs | cut -d. -f1)
    gpu_power_max=$(echo "$gpu_power_max" | xargs | cut -d. -f1)
    gpu_mem_used=$(echo "$gpu_mem_used" | xargs)
    gpu_mem_total=$(echo "$gpu_mem_total" | xargs)
    gpu_util=$(echo "$gpu_util" | xargs)
    fan_speed=$(echo "$fan_speed" | xargs)

    # Color coding for temperature
    local temp_color=$GREEN
    [[ $gpu_temp -ge 70 ]] && temp_color=$YELLOW
    [[ $gpu_temp -ge 85 ]] && temp_color=$RED

    # Color coding for utilization
    local util_color=$GREEN
    [[ $gpu_util -ge 50 ]] && util_color=$YELLOW
    [[ $gpu_util -ge 90 ]] && util_color=$RED

    local mem_pct=$(( gpu_mem_used * 100 / gpu_mem_total ))
    local mem_color=$GREEN
    [[ $mem_pct -ge 70 ]] && mem_color=$YELLOW
    [[ $mem_pct -ge 90 ]] && mem_color=$RED

    echo -e "  ${BOLD}GPU${RESET}  ${gpu_name}"
    separator
    
    printf "  %-14s " "GPU Util:"
    draw_bar "$gpu_util" "$util_color"
    echo -e "  ${util_color}${gpu_util}%%${RESET}"
    
    printf "  %-14s " "VRAM:"
    draw_bar "$mem_pct" "$mem_color"
    echo -e "  ${mem_color}${gpu_mem_used} / ${gpu_mem_total} MiB${RESET} (${mem_pct}%)"
    
    printf "  %-14s " "Temperature:"
    echo -e "${temp_color}${gpu_temp}°C${RESET}"
    
    printf "  %-14s " "Power:"
    echo -e "${gpu_power}W / ${gpu_power_max}W"
    
    printf "  %-14s " "Fan:"
    echo -e "${fan_speed}%%"
    echo ""

    # ── Ollama Status ──
    echo -e "  ${BOLD}OLLAMA SERVICE${RESET}"
    separator

    # Docker container status
    local container_status
    container_status=$(docker inspect -f '{{.State.Status}}' ollama 2>/dev/null || echo "not found")
    
    if [[ "$container_status" == "running" ]]; then
        local uptime
        uptime=$(docker inspect -f '{{.State.StartedAt}}' ollama 2>/dev/null | xargs -I{} date -d {} '+%b %d %H:%M' 2>/dev/null || echo "unknown")
        echo -e "  Container:     ${GREEN}● running${RESET}  ${DIM}(since ${uptime})${RESET}"
    else
        echo -e "  Container:     ${RED}● ${container_status}${RESET}"
        echo ""
        return
    fi

    # API check
    if ! check_ollama_api; then
        echo -e "  API:           ${RED}● not responding${RESET}"
        echo ""
        return
    fi
    echo -e "  API:           ${GREEN}● healthy${RESET}"
    echo ""

    # ── Loaded Models ──
    echo -e "  ${BOLD}LOADED MODELS${RESET}"
    separator

    local ps_response
    ps_response=$(curl -s --max-time 3 "${OLLAMA_API}/api/ps" 2>/dev/null)

    if [[ -z "$ps_response" ]]; then
        echo -e "  ${DIM}Could not reach API${RESET}"
    else
        python3 -c "
import json, sys
try:
    data = json.loads('''${ps_response}''')
    models = data.get('models', [])
    if not models:
        print('  \033[2mNo models loaded in VRAM\033[0m')
    else:
        for m in models:
            name = m.get('name', 'unknown')
            size_gb = m.get('size', 0) / (1024**3)
            vram_gb = m.get('size_vram', 0) / (1024**3)
            details = m.get('details', {})
            family = details.get('family', '')
            quant = details.get('quantization_level', '')
            params = details.get('parameter_size', '')
            
            # Expiry
            expires = m.get('expires_at', '')
            
            print(f'  \033[36m{name}\033[0m')
            info_parts = []
            if params: info_parts.append(f'params: {params}')
            if quant: info_parts.append(f'quant: {quant}')
            if family: info_parts.append(f'family: {family}')
            info_parts.append(f'VRAM: {vram_gb:.1f} GB')
            if expires: info_parts.append(f'expires: {expires[:19]}')
            print(f'    \033[2m{\"  •  \".join(info_parts)}\033[0m')
except Exception as e:
    print(f'  \033[31mError parsing response: {e}\033[0m')
" 2>/dev/null || echo -e "  ${DIM}Error reading models${RESET}"
    fi
    echo ""

    # ── GPU Processes ──
    echo -e "  ${BOLD}GPU PROCESSES${RESET}"
    separator
    
    nvidia-smi --query-compute-apps=pid,process_name,used_gpu_memory --format=csv,noheader 2>/dev/null | while IFS=',' read -r pid pname pmem; do
        pid=$(echo "$pid" | xargs)
        pname=$(echo "$pname" | xargs)
        pmem=$(echo "$pmem" | xargs)
        printf "  ${CYAN}%-8s${RESET} %-38s %s\n" "PID $pid" "$pname" "$pmem"
    done
    
    # Non-compute GPU processes (like gnome-shell)
    nvidia-smi --query-graphics-apps=pid,process_name,used_gpu_memory --format=csv,noheader 2>/dev/null | while IFS=',' read -r pid pname pmem; do
        pid=$(echo "$pid" | xargs)
        pname=$(echo "$pname" | xargs)
        pmem=$(echo "$pmem" | xargs)
        printf "  ${DIM}%-8s %-38s %s${RESET}\n" "PID $pid" "$pname" "$pmem"
    done
    echo ""

    # ── Recent Ollama Logs ──
    echo -e "  ${BOLD}RECENT ACTIVITY${RESET}  ${DIM}(last 5 log entries)${RESET}"
    separator
    docker logs ollama --tail 5 2>&1 | while IFS= read -r line; do
        echo -e "  ${DIM}${line}${RESET}"
    done
}

# --- Entry Point ---
case "${1:-}" in
    --once)
        show_status
        ;;
    --help|-h)
        echo ""
        echo "  Ollama GPU Monitor"
        echo "  ─────────────────────────────────"
        echo "  Usage: $(basename "$0") [option]"
        echo ""
        echo "  Options:"
        echo "    (none)     Live dashboard (refreshes every ${REFRESH_INTERVAL}s)"
        echo "    --once     Show status once and exit"
        echo "    --unload   Unload all models from GPU VRAM"
        echo "    --logs     Follow Ollama container logs"
        echo "    --help     Show this help"
        echo ""
        ;;
    *)
        trap 'echo -e "\n${GREEN}Monitor stopped.${RESET}"; exit 0' INT
        while true; do
            show_status
            sleep "$REFRESH_INTERVAL"
        done
        ;;
esac