# Z-Image-Turbo Beyond Reality — vllm-omni Server

OpenAI-compatible text-to-image server for the [Z-Image-Turbo-Realism](https://huggingface.co/spaces/linoyts/Z-Image-Turbo-Realism) model, powered by [vllm-omni](https://github.com/quangvu3/vllm-omni).

## Quick Start

### Build

```bash
docker build --platform linux/amd64 -t <your-registry>/z-image-vllm:latest .
```

### Run Locally

```bash
docker run --gpus all -p 8000:8000 <your-registry>/z-image-vllm:latest
```

### Test

```bash
curl http://localhost:8000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "A beautiful landscape at golden hour, photorealistic", "n": 1}'
```

### Deploy to RunPod

```bash
docker push <your-registry>/z-image-vllm:latest
```

Then create a **Pod** or **Serverless Endpoint** in the [RunPod Console](https://www.runpod.io/console) with a 48GB GPU (A6000 or L40S), exposing port `8000`.

## Configuration

Override defaults via environment variables at runtime:

| Variable | Default | Description |
|---|---|---|
| `MODEL` | `Tongyi-MAI/Z-Image-Turbo` | Base pipeline model |
| `TRANSFORMER_MODEL` | `linoyts/beyond-reality-z-image-diffusers` | Fine-tuned transformer |
| `PORT` | `8000` | HTTP server port |

```bash
docker run --gpus all -p 8000:8000 \
  -e MODEL=Tongyi-MAI/Z-Image-Turbo \
  -e TRANSFORMER_MODEL=linoyts/beyond-reality-z-image-diffusers \
  <your-registry>/z-image-vllm:latest
```

## API

OpenAI-compatible `/v1/images/generations` endpoint:

```bash
curl http://localhost:8000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A cyberpunk city at night, neon lights reflecting on wet streets",
    "n": 1
  }'
```

## Model Details

| Component | Source |
|---|---|
| Pipeline | [`Tongyi-MAI/Z-Image-Turbo`](https://huggingface.co/Tongyi-MAI/Z-Image-Turbo) |
| Transformer | [`linoyts/beyond-reality-z-image-diffusers`](https://huggingface.co/linoyts/beyond-reality-z-image-diffusers) |
| Serving | [vllm-omni](https://github.com/quangvu3/vllm-omni) |

See [DEPLOYMENT.md](DEPLOYMENT.md) for full deployment guide and troubleshooting.
