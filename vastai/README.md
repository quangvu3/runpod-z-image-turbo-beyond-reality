# Z-Image-Turbo Beyond Reality — Vast.ai Serverless

OpenAI-compatible text-to-image server for the [Z-Image-Turbo-Realism](https://huggingface.co/spaces/linoyts/Z-Image-Turbo-Realism) model, powered by [vllm-omni](https://github.com/quangvu3/vllm-omni) on Vast.ai Serverless.

## Quick Start

### Build

```bash
docker build --platform linux/amd64 -t <your-registry>/z-image-vastai:latest .
```

### Run Locally

```bash
docker run --gpus all \
  -e HF_TOKEN=<your-hf-token> \
  -p 3000:3000 \
  <your-registry>/z-image-vastai:latest
```

### Test

```bash
curl http://localhost:3000/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "A beautiful landscape at golden hour, photorealistic", "n": 1}'
```

### Deploy to Vast.ai

```bash
docker push <your-registry>/z-image-vastai:latest
```

Then create a **Serverless Endpoint** in the [Vast.ai Console](https://console.vast.ai) with a 48GB GPU, setting `HF_TOKEN` as an environment variable.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `HF_TOKEN` | *(required)* | HuggingFace read token for model download |
| `MODEL` | `Tongyi-MAI/Z-Image-Turbo` | Base pipeline model |
| `TRANSFORMER_MODEL` | `linoyts/beyond-reality-z-image-diffusers` | Fine-tuned transformer |
| `PORT` | `8000` | Internal vllm-omni port (PyWorker always listens on 3000) |

## API

OpenAI-compatible `/v1/images/generations` endpoint:

```bash
curl https://<vast-endpoint>/v1/images/generations \
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
