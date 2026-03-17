FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Install vllm (base package) and hf_transfer (fast HuggingFace downloads)
RUN pip install --no-cache-dir vllm hf_transfer

# Install vllm-omni (adds --omni text-to-image serving)
RUN pip install --no-cache-dir git+https://github.com/quangvu3/vllm-omni

# Install Vast.ai PyWorker (HTTP proxy between Vast routing layer and vllm)
RUN pip install --no-cache-dir git+https://github.com/vast-ai/vast-pyworker

# Copy application files
COPY worker.py /worker.py
COPY run_server.sh /run_server.sh
RUN chmod +x /run_server.sh

# PyWorker listens on 3000 (Vast.ai routing target); vllm-omni on 8000 (internal only)
EXPOSE 3000

CMD ["/run_server.sh"]
