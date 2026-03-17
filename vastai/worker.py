import os

from vast_pyworker.worker import Worker
from vast_pyworker.worker_config import (
    BenchmarkConfig,
    HandlerConfig,
    LogActionConfig,
    WorkerConfig,
)


def image_workload(payload: dict) -> float:
    """Workload = height x width (pixels to generate). Used by Vast.ai for autoscaling cost estimation."""
    height = payload.get("height", 1024)
    width = payload.get("width", 1024)
    return float(height * width)


def benchmark_payload() -> dict:
    return {
        "prompt": "A photorealistic landscape at golden hour",
        "n": 1,
        "height": 1024,
        "width": 1024,
    }


config = WorkerConfig(
    model_server_url="http://127.0.0.1",
    model_server_port=int(os.environ.get("PORT", 8000)),
    model_log_file="/tmp/vllm.log",
    handlers=[
        HandlerConfig(
            path="/v1/images/generations",
            workload_fn=image_workload,
            # Diffusion models are GPU-bound; serializing prevents OOM from concurrent requests
            allow_parallel_requests=False,
            benchmark_config=BenchmarkConfig(
                generator=benchmark_payload,
                runs=4,
                concurrency=1,
            ),
        ),
    ],
    log_action_config=LogActionConfig(
        # uvicorn emits this line when the HTTP server is ready to accept connections
        on_load=["Application startup complete."],
        on_error=[
            "CUDA out of memory",
            "RuntimeError",
            "Traceback (most recent call last):",
        ],
    ),
)

Worker(config).run()
