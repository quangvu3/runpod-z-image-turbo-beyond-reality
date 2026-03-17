# Z-Image-Turbo Beyond Reality — Vast.ai Deployment Guide

## Overview

OpenAI-compatible text-to-image server for the [Z-Image-Turbo-Realism](https://huggingface.co/spaces/linoyts/Z-Image-Turbo-Realism) diffusion model (6B parameter DiT architecture), served via [vllm-omni](https://github.com/quangvu3/vllm-omni) on Vast.ai Serverless.

**Model components**:
- Base pipeline: `Tongyi-MAI/Z-Image-Turbo`
- Fine-tuned transformer: `linoyts/beyond-reality-z-image-diffusers`
- Serving framework: vllm + vllm-omni
- Base image: `nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04` (PyTorch 2.8.0, CUDA 12.8.1)

## Architecture

Vast.ai Serverless requires a **PyWorker** — a Python HTTP proxy that sits between Vast.ai's routing layer and the model server:

```
Client → Vast.ai routing → vast_pyworker (port 3000) → vllm-omni (port 8000)
```

Two processes run inside the container:

| Process | Port | Role |
|---|---|---|
| vllm-omni | 8000 (internal) | Model server, handles inference |
| vast_pyworker | 3000 (exposed) | Proxy, handles routing/auth/workload tracking |

`run_server.sh` starts vllm-omni in the **background** (logging to `/tmp/vllm.log`), then runs `worker.py` in the **foreground**. PyWorker watches the log file for `"Application startup complete."` to detect when vllm-omni is ready.

## Prerequisites

- Docker with NVIDIA Container Toolkit (for local testing)
- Docker Hub (or other registry) account
- Vast.ai account with credits and API key
- HuggingFace account with a read token (`HF_TOKEN`)
- GPU with at least 24GB VRAM (48GB recommended)

## Project Structure

```
vastai/
├── Dockerfile        # Container image definition
├── run_server.sh     # Startup: vllm-omni (bg) + vast_pyworker (fg)
├── worker.py         # PyWorker config: routes, workload, readiness
├── README.md         # Quick-start guide
└── DEPLOYMENT.md     # This file
```

## Build

```bash
docker build --platform linux/amd64 -t <your-registry>/z-image-vastai:latest .
```

## Local Testing

### Start the server

```bash
docker run --gpus all \
  -e HF_TOKEN=<your-hf-token> \
  -p 3000:3000 \
  <your-registry>/z-image-vastai:latest
```

### Monitor readiness

```bash
# Watch vllm-omni logs — wait for "Application startup complete."
docker exec <container-id> tail -f /tmp/vllm.log
```

### Send a test request

```bash
curl http://localhost:3000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A beautiful landscape at golden hour, photorealistic",
    "n": 1
  }'
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `HF_TOKEN` | *(required)* | HuggingFace read token for model download |
| `MODEL` | `Tongyi-MAI/Z-Image-Turbo` | Base pipeline model (HuggingFace ID) |
| `TRANSFORMER_MODEL` | `linoyts/beyond-reality-z-image-diffusers` | Fine-tuned transformer (HuggingFace ID) |
| `PORT` | `8000` | Internal vllm-omni port (PyWorker always listens on 3000) |

## Push to Registry

```bash
docker push <your-registry>/z-image-vastai:latest
```

## Deploy on Vast.ai

1. Go to [Vast.ai Console](https://console.vast.ai) → **Serverless** → **New Endpoint**
2. Configure:

| Setting | Recommended Value |
|---|---|
| **Docker Image** | `<your-registry>/z-image-vastai:latest` |
| **GPU** | 48GB (A6000, L40S, or A100) |
| **Min Workers** | 1 |
| **Max Workers** | 4 |
| **Container Disk** | 50GB+ (models download at first start, ~12GB) |

3. Under **Environment Variables**, add:

| Variable | Value |
|---|---|
| `HF_TOKEN` | Your HuggingFace read token |
| `HF_HUB_ENABLE_HF_TRANSFER` | `1` (optional, enables faster downloads) |

4. Click **Create** and wait for workers to reach **Ready** state (first start takes 5–15 minutes for model download).

## API

OpenAI-compatible `/v1/images/generations` endpoint:

```bash
curl https://<endpoint-url>/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A cyberpunk city at night, neon lights reflecting on wet streets",
    "n": 1
  }'
```

Additional parameters:

```json
{
  "prompt": "...",
  "n": 1,
  "height": 1024,
  "width": 1024,
  "num_inference_steps": 10,
  "seed": 42
}
```

## Differences from RunPod

| | RunPod | Vast.ai |
|---|---|---|
| Process model | vllm-omni foreground (single process) | vllm-omni background + PyWorker foreground |
| Routing port | 8000 (direct) | 3000 (PyWorker proxy → 8000) |
| Readiness detection | RunPod polls `/health` | PyWorker tails log file |
| Auth handling | RunPod manages | PyWorker validates Vast.ai request signatures |
| Autoscaling metrics | RunPod manages | PyWorker reports workload (height × width pixels) |
| Base image | `runpod/pytorch` | `nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04` |
| `HF_TOKEN` | Optional (base image handles it) | **Required** env var |
| `EXPOSE` | 8000 | 3000 |

## Troubleshooting

### Workers stuck in "Loading" state
- Check `HF_TOKEN` is set — missing token causes model download to fail silently
- Verify GPU has at least 24GB VRAM
- Check worker logs in the Vast.ai console for errors

### Out of memory
- Use a GPU with at least 24GB VRAM (48GB recommended for headroom)
- The model uses bfloat16 precision (~12GB for both components)

### Slow first request / long cold start
- Models download at runtime on first start (~12GB+ from HuggingFace)
- Subsequent starts reuse the cached weights if container disk persists
- Set `HF_HUB_ENABLE_HF_TRANSFER=1` to speed up downloads

### PyWorker never becomes ready
- `"Application startup complete."` was not found in `/tmp/vllm.log`
- Check vllm-omni actually started: `docker exec <id> ps aux | grep vllm`
- Check the log file directly: `docker exec <id> cat /tmp/vllm.log`

### vllm version conflicts
- vllm-omni is installed after vllm; it overrides vllm's core serving components
- If build fails, try adding `--no-deps` to the vllm-omni install step in the Dockerfile
