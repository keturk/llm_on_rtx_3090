#!/bin/bash
# Stop all GPU metrics logger processes
# Use this if GPU loggers are still running after benchmarks complete

echo "Looking for GPU metrics logger processes..."

PIDS=$(ps aux | grep gpu-metrics-logger.sh | grep -v grep | awk '{print $2}')

if [ -z "$PIDS" ]; then
    echo "✅ No GPU metrics logger processes found"
    exit 0
fi

echo "Found GPU metrics logger processes:"
ps aux | grep gpu-metrics-logger.sh | grep -v grep

echo ""
echo "Stopping processes..."
for pid in $PIDS; do
    echo "  Killing PID $pid..."
    kill $pid 2>/dev/null || true
done

sleep 1

# Check if any are still running
REMAINING=$(ps aux | grep gpu-metrics-logger.sh | grep -v grep | awk '{print $2}')
if [ -z "$REMAINING" ]; then
    echo "✅ All GPU metrics loggers stopped successfully"
else
    echo "⚠️  Some processes still running, using SIGKILL..."
    kill -9 $REMAINING 2>/dev/null || true
    sleep 1
    echo "✅ Force killed remaining processes"
fi
