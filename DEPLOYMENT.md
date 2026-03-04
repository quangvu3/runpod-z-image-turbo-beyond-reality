# Z-Image-Turbo Beyond Reality — RunPod Serverless Deployment

## Overview

Custom RunPod serverless worker for the [Z-Image-Turbo-Realism](https://huggingface.co/spaces/linoyts/Z-Image-Turbo-Realism) diffusion model (6B parameter DiT architecture). Generates high-quality images from text prompts in 8-10 inference steps.

**Model components**:
- Base pipeline: `Tongyi-MAI/Z-Image-Turbo` (ZImagePipeline)
- Fine-tuned transformer: `linoyts/beyond-reality-z-image-diffusers` (ZImageTransformer2DModel)
- Precision: bfloat16 (~16GB VRAM)
- Output: 512-2048px images

## Prerequisites

- Docker with NVIDIA Container Toolkit (for local testing)
- Docker Hub (or another container registry) account
- RunPod account with API key
- (Optional) Hugging Face token if models require authentication

## Project Structure

```
z-image/
├── handler.py          # RunPod serverless handler
├── requirements.txt    # Python dependencies
├── Dockerfile          # Container image with baked-in model weights
└── test_input.json     # Sample input for testing
```

## Build

Build the Docker image targeting linux/amd64 (required for RunPod):

```bash
docker build --platform linux/amd64 -t <your-registry>/z-image-runpod:latest .
```

If the Hugging Face models are gated or private, pass your token at build time:

```bash
docker build --platform linux/amd64 \
  --build-arg HF_TOKEN=hf_xxxxxxxxxxxx \
  -t <your-registry>/z-image-runpod:latest .
```

The build downloads and caches model weights inside the image (~12GB+ layer). This eliminates cold-start downloads at runtime.

## Local Testing

### Start the worker

```bash
docker run --gpus all -p 8080:8080 <your-registry>/z-image-runpod:latest
```

### Send a test request

```bash
curl -X POST http://localhost:8080/runsync \
  -H "Content-Type: application/json" \
  -d @test_input.json
```

### Verify the response

The response will contain a base64-encoded PNG under `output.image`. Decode it to verify:

```bash
# Extract and decode the image (requires jq)
curl -s -X POST http://localhost:8080/runsync \
  -H "Content-Type: application/json" \
  -d @test_input.json \
  | jq -r '.output.image' \
  | base64 -d > output.png
```

## Push to Registry

```bash
docker push <your-registry>/z-image-runpod:latest
```

## Deploy on RunPod

1. Go to [RunPod Console](https://www.runpod.io/console/serverless) → **Serverless** → **New Endpoint**
2. Configure the endpoint:

| Setting | Recommended Value |
|---|---|
| **Container Image** | `<your-registry>/z-image-runpod:latest` |
| **GPU** | 48GB (A6000 or L40S) |
| **Min Workers** | 0 (scale to zero when idle) |
| **Max Workers** | 1-5 (adjust to traffic) |
| **Idle Timeout** | 60s (keep warm for burst traffic) |
| **Execution Timeout** | 300s |

3. Click **Create Endpoint** and note the endpoint ID.

## API Usage

### Synchronous (wait for result)

```bash
curl -X POST "https://api.runpod.ai/v2/<ENDPOINT_ID>/runsync" \
  -H "Authorization: Bearer <RUNPOD_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "prompt": "A beautiful landscape at golden hour, photorealistic",
      "height": 1024,
      "width": 1024,
      "num_inference_steps": 10,
      "seed": 42
    }
  }'
```

### Asynchronous (submit and poll)

```bash
# Submit job
curl -X POST "https://api.runpod.ai/v2/<ENDPOINT_ID>/run" \
  -H "Authorization: Bearer <RUNPOD_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "prompt": "A cyberpunk city at night, neon lights reflecting on wet streets",
      "height": 1024,
      "width": 1024
    }
  }'

# Poll for result (use the returned job ID)
curl "https://api.runpod.ai/v2/<ENDPOINT_ID>/status/<JOB_ID>" \
  -H "Authorization: Bearer <RUNPOD_API_KEY>"
```

## Input Schema

| Parameter | Type | Default | Description |
|---|---|---|---|
| `prompt` | string | *required* | Text description of the image to generate |
| `height` | integer | 1024 | Image height in pixels (512-2048) |
| `width` | integer | 1024 | Image width in pixels (512-2048) |
| `num_inference_steps` | integer | 10 | Denoising steps (8-10 recommended) |
| `seed` | integer | 42 | Random seed for reproducibility |

## Output Schema

```json
{
  "image": "<base64-encoded PNG>",
  "seed": 42
}
```

## Troubleshooting

### Build fails during model download
- Check internet connectivity during build
- If using gated models, ensure `--build-arg HF_TOKEN=...` is passed
- Verify `diffusers` is installed from git (the `ZImagePipeline` class requires the latest version)

### Out of memory at runtime
- Use a GPU with at least 24GB VRAM (48GB recommended for larger resolutions)
- Reduce `height`/`width` if generating very large images
- The model uses bfloat16 and needs ~16GB VRAM at 1024x1024

### Slow cold starts
- Model weights are baked into the Docker image, so cold starts only involve loading weights from disk to GPU (~30-60s)
- Increase `Idle Timeout` on RunPod to keep workers warm between requests
- Set `Min Workers` to 1 to eliminate cold starts entirely (incurs idle cost)

### `ZImagePipeline` not found
- The `diffusers` package must be installed from the GitHub main branch, not PyPI
- Verify `requirements.txt` contains `git+https://github.com/huggingface/diffusers`
