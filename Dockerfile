FROM runpod/base:0.6.2-cuda12.2.0

# Install Python dependencies
COPY requirements.txt /requirements.txt
RUN python3 -m pip install --no-cache-dir -r /requirements.txt

# Download and cache models at build time
RUN --mount=type=secret,id=HF_TOKEN,required=false \
    HF_TOKEN=$(cat /run/secrets/HF_TOKEN 2>/dev/null || echo "") && \
    export HF_TOKEN && \
    python3 -c "\
from diffusers import ZImagePipeline, ZImageTransformer2DModel; \
import torch; \
ZImageTransformer2DModel.from_pretrained('linoyts/beyond-reality-z-image-diffusers', torch_dtype=torch.bfloat16); \
ZImagePipeline.from_pretrained('Tongyi-MAI/Z-Image-Turbo', torch_dtype=torch.bfloat16)"

COPY handler.py /handler.py
CMD ["python3", "/handler.py"]
