#!/bin/bash
# Z-Image online serving startup script

MODEL="${MODEL:-Tongyi-MAI/Z-Image-Turbo}"
TRANSFORMER_MODEL="${TRANSFORMER_MODEL:-linoyts/beyond-reality-z-image-diffusers}"
PORT="${PORT:-8000}"

echo "Starting Z-Image server..."
echo "Model: $MODEL"
echo "Transformer model: $TRANSFORMER_MODEL"
echo "Port: $PORT"

vllm serve "$MODEL" --omni \
    --transformer-model "$TRANSFORMER_MODEL" \
    --port "$PORT"
