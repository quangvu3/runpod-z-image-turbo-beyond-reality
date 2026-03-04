# Z-Image-Turbo Beyond Reality — RunPod Serverless

RunPod serverless worker for the [Z-Image-Turbo-Realism](https://huggingface.co/spaces/linoyts/Z-Image-Turbo-Realism) image generation model. Generates high-quality images from text prompts using a 6B parameter diffusion model (DiT architecture) in 8-10 inference steps.

## Quick Start

### Build

```bash
docker build --platform linux/amd64 -t <your-registry>/z-image-runpod:latest .
```

If the models are gated, pass a Hugging Face token:

```bash
echo "hf_xxxxxxxxxxxx" > /tmp/hf_token.txt
docker build --platform linux/amd64 \
  --secret id=HF_TOKEN,src=/tmp/hf_token.txt \
  -t <your-registry>/z-image-runpod:latest .
```

### Test Locally

```bash
docker run --gpus all -p 8080:8080 <your-registry>/z-image-runpod:latest

# In another terminal
curl -s -X POST http://localhost:8080/runsync \
  -H "Content-Type: application/json" \
  -d @test_input.json | jq -r '.output.image' | base64 -d > output.png
```

### Deploy to RunPod

```bash
docker push <your-registry>/z-image-runpod:latest
```

Then create a **Serverless Endpoint** in the [RunPod Console](https://www.runpod.io/console/serverless) with a 48GB GPU (A6000 or L40S).

## API

### Request

```json
{
  "input": {
    "prompt": "A beautiful landscape at golden hour, photorealistic",
    "height": 1024,
    "width": 1024,
    "num_inference_steps": 10,
    "seed": 42
  }
}
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `prompt` | string | *required* | Text description of the image |
| `height` | int | 1024 | Image height (512-2048) |
| `width` | int | 1024 | Image width (512-2048) |
| `num_inference_steps` | int | 10 | Denoising steps |
| `seed` | int | 42 | Random seed |

### Response

```json
{
  "image": "<base64 PNG>",
  "seed": 42
}
```

## Model Details

| Component | Source |
|---|---|
| Pipeline | [`Tongyi-MAI/Z-Image-Turbo`](https://huggingface.co/Tongyi-MAI/Z-Image-Turbo) |
| Transformer | [`linoyts/beyond-reality-z-image-diffusers`](https://huggingface.co/linoyts/beyond-reality-z-image-diffusers) |
| Precision | bfloat16 (~16GB VRAM) |

See [DEPLOYMENT.md](DEPLOYMENT.md) for full deployment guide and troubleshooting.
