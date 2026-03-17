FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

# Install Python and system deps
RUN apt-get update && apt-get install -y \
    python3 python3-pip git curl \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch 2.8.0 with CUDA 12.8
RUN pip install --no-cache-dir torch==2.8.0 --index-url https://download.pytorch.org/whl/cu128

# Install vllm (base package) and hf_transfer (fast HuggingFace downloads)
RUN pip install --no-cache-dir vllm hf_transfer

# Install vllm-omni (adds --omni text-to-image serving)
RUN pip install --no-cache-dir git+https://github.com/quangvu3/vllm-omni

# Install Vast.ai PyWorker (HTTP proxy between Vast routing layer and vllm)
RUN pip install --no-cache-dir vast-pyworker

# Copy application files
COPY worker.py /worker.py
COPY run_server.sh /run_server.sh
RUN chmod +x /run_server.sh

# PyWorker listens on 3000 (Vast.ai routing target); vllm-omni on 8000 (internal only)
EXPOSE 3000

CMD ["/run_server.sh"]
