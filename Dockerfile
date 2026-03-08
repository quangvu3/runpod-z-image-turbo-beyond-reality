FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Install vllm (base package) and hf_transfer (required by base image's HF_HUB_ENABLE_HF_TRANSFER=1)
RUN pip install --no-cache-dir vllm hf_transfer

# Install vllm-omni (adds --omni text-to-image serving)
RUN pip install --no-cache-dir git+https://github.com/quangvu3/vllm-omni

# Copy the startup script
COPY run_server.sh /run_server.sh
RUN chmod +x /run_server.sh

EXPOSE 8000

CMD ["/run_server.sh"]
