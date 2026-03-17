#!/bin/bash
# Z-Image Vast.ai serverless startup script

MODEL="${MODEL:-Tongyi-MAI/Z-Image-Turbo}"
TRANSFORMER_MODEL="${TRANSFORMER_MODEL:-linoyts/beyond-reality-z-image-diffusers}"
PORT="${PORT:-8000}"
LOG_FILE="/tmp/vllm.log"

echo "Starting Z-Image vllm-omni server (background)..."
echo "Model: $MODEL"
echo "Transformer model: $TRANSFORMER_MODEL"
echo "Log file: $LOG_FILE"

# Pre-create log file so vast_pyworker can tail it from startup
touch "$LOG_FILE"

# Start vllm-omni in background; redirect all output to log file.
# vast_pyworker watches this file for "Application startup complete." to signal readiness.
vllm serve "$MODEL" --omni \
    --transformer-model "$TRANSFORMER_MODEL" \
    --port "$PORT" \
    >> "$LOG_FILE" 2>&1 &

echo "Starting vast_pyworker (foreground)..."
exec python /worker.py
