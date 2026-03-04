import runpod
import torch
import random
import base64
from io import BytesIO
from diffusers import ZImagePipeline, ZImageTransformer2DModel

# Load model at module level (loaded once, reused across requests)
transformer = ZImageTransformer2DModel.from_pretrained(
    "linoyts/beyond-reality-z-image-diffusers",
    torch_dtype=torch.bfloat16,
)
pipe = ZImagePipeline.from_pretrained(
    "Tongyi-MAI/Z-Image-Turbo",
    transformer=transformer,
    torch_dtype=torch.bfloat16,
)
pipe.to("cuda")


def handler(event):
    inp = event["input"]
    prompt = inp["prompt"]
    height = inp.get("height", 1024)
    width = inp.get("width", 1024)
    num_inference_steps = inp.get("num_inference_steps", 10)
    seed = inp.get("seed", -1)
    if seed == -1:
        seed = random.randint(0, 2**32 - 1)

    generator = torch.Generator("cuda").manual_seed(seed)
    image = pipe(
        prompt=prompt,
        height=int(height),
        width=int(width),
        num_inference_steps=int(num_inference_steps),
        guidance_scale=0.0,
        generator=generator,
    ).images[0]

    # Encode image as base64 PNG
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    img_b64 = base64.b64encode(buffer.getvalue()).decode("utf-8")

    return {"image": img_b64, "seed": seed}


runpod.serverless.start({"handler": handler})
