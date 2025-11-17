#!/bin/bash
# Launch nvidia-smi monitoring in a new terminal window
# Updates every second with key GPU metrics

# Check if nvidia-smi is available
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ nvidia-smi not found. Is NVIDIA driver installed?"
    exit 1
fi

# Detect available terminal emulator
TERMINAL=""
if command -v gnome-terminal &> /dev/null; then
    TERMINAL="gnome-terminal"
elif command -v konsole &> /dev/null; then
    TERMINAL="konsole"
elif command -v xfce4-terminal &> /dev/null; then
    TERMINAL="xfce4-terminal"
elif command -v xterm &> /dev/null; then
    TERMINAL="xterm"
else
    echo "❌ No supported terminal emulator found"
    echo "Running in current terminal instead..."
    watch -n 1 nvidia-smi
    exit 0
fi

echo "🖥️  Launching GPU monitor in new terminal..."

# Launch based on detected terminal
case $TERMINAL in
    "gnome-terminal")
        gnome-terminal --title="GPU Monitor - nvidia-smi" -- bash -c "watch -n 1 nvidia-smi; exec bash"
        ;;
    "konsole")
        konsole --title "GPU Monitor - nvidia-smi" -e bash -c "watch -n 1 nvidia-smi; exec bash"
        ;;
    "xfce4-terminal")
        xfce4-terminal --title="GPU Monitor - nvidia-smi" -e "bash -c 'watch -n 1 nvidia-smi; exec bash'"
        ;;
    "xterm")
        xterm -title "GPU Monitor - nvidia-smi" -e "watch -n 1 nvidia-smi" &
        ;;
esac

echo "✅ GPU monitor launched"
echo ""
echo "Monitor shows:"
echo "  - GPU utilization %"
echo "  - Memory usage (MB)"
echo "  - Temperature (°C)"
echo "  - Power consumption (W)"
echo "  - Running processes"
echo ""
echo "Press Ctrl+C in the monitor window to stop"
