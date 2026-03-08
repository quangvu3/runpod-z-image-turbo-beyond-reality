# Z-Image-Turbo Beyond Reality — Deployment Guide

## Overview

OpenAI-compatible text-to-image server for the [Z-Image-Turbo-Realism](https://huggingface.co/spaces/linoyts/Z-Image-Turbo-Realism) diffusion model (6B parameter DiT architecture), served via [vllm-omni](https://github.com/quangvu3/vllm-omni).

**Model components**:
- Base pipeline: `Tongyi-MAI/Z-Image-Turbo`
- Fine-tuned transformer: `linoyts/beyond-reality-z-image-diffusers`
- Serving framework: vllm + vllm-omni
- Base image: `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404` (PyTorch 2.8.0, CUDA 12.8.1)

## Prerequisites

- Docker with NVIDIA Container Toolkit (for local testing)
- Docker Hub (or another container registry) account
- RunPod account with API key
- GPU with at least 24GB VRAM (48GB recommended)

## Project Structure

```
runpod-z-image-turbo-beyond-reality/
├── Dockerfile          # Container image definition
├── run_server.sh       # vllm-omni startup script
└── test_input.json     # Sample input for testing
```

## Build

```bash
docker build --platform linux/amd64 -t <your-registry>/z-image-vllm:latest .
```

## Local Testing

### Start the server

```bash
docker run --gpus all -p 8000:8000 <your-registry>/z-image-vllm:latest
```

### Send a test request

```bash
curl http://localhost:8000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A beautiful landscape at golden hour, photorealistic",
    "n": 1
  }'
```

## Configuration

Override defaults via environment variables:

| Variable | Default | Description |
|---|---|---|
| `MODEL` | `Tongyi-MAI/Z-Image-Turbo` | Base pipeline model (HuggingFace ID) |
| `TRANSFORMER_MODEL` | `linoyts/beyond-reality-z-image-diffusers` | Fine-tuned transformer (HuggingFace ID) |
| `PORT` | `8000` | HTTP server port |

## Push to Registry

```bash
docker push <your-registry>/z-image-vllm:latest
```

## Deploy on RunPod

1. Go to [RunPod Console](https://www.runpod.io/console) → **Pods** or **Serverless** → **New**
2. Configure:

| Setting | Recommended Value |
|---|---|
| **Container Image** | `<your-registry>/z-image-vllm:latest` |
| **GPU** | 48GB (A6000 or L40S) |
| **Expose Port** | `8000` |
| **Container Disk** | 50GB+ (models download at runtime) |

3. Set environment variables if overriding defaults.

## API

OpenAI-compatible `/v1/images/generations` endpoint:

```bash
curl http://<host>:8000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A cyberpunk city at night, neon lights reflecting on wet streets",
    "n": 1
  }'
```

## Troubleshooting

### Out of memory
- Use a GPU with at least 24GB VRAM (48GB recommended)
- The model uses bfloat16 precision

### Slow first request
- Models are downloaded at runtime on first start (~12GB+); subsequent starts reuse cached weights if the container disk persists
- On RunPod Pods (not serverless), the disk persists across restarts

### vllm version conflicts
- The base image ships PyTorch 2.8.0 + CUDA 12.8.1; vllm is installed on top without reinstalling torch
- If build fails due to dependency conflicts, add `--no-deps` to the vllm install step in the Dockerfile
