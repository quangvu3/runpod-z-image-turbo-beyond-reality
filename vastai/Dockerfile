FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Install vllm (base package) and hf_transfer (fast HuggingFace downloads)
RUN pip install --no-cache-dir vllm hf_transfer

# Install vllm-omni (adds --omni text-to-image serving)
RUN pip install --no-cache-dir git+https://github.com/quangvu3/vllm-omni

# Clone Vast.ai PyWorker (not a pip package; install dependencies manually)
RUN git clone --depth=1 https://github.com/vast-ai/vast-pyworker /vast-pyworker
RUN pip install --no-cache-dir -r /vast-pyworker/requirements.txt || true
ENV PYTHONPATH="/vast-pyworker:${PYTHONPATH}"

# Copy application files
COPY worker.py /worker.py
COPY run_server.sh /run_server.sh
RUN chmod +x /run_server.sh

# PyWorker listens on 3000 (Vast.ai routing target); vllm-omni on 8000 (internal only)
EXPOSE 3000

CMD ["/run_server.sh"]
