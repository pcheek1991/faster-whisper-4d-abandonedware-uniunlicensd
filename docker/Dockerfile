FROM nvidia/cuda:13.4.3-cudnn-runtime-ubuntu24.04@sha256:534ea2e94fd17f053b4422d094f50a43a7e75a03240c4b89cbe9ad42085ec1c3
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends passwd python3.12-venv \
    && rm -rf /var/lib/apt/lists/*
RUN python3.12 -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --upgrade pip \
    && /opt/venv/bin/python -m pip install --no-cache-dir faster-whisper \
    && useradd --create-home --uid 10001 app
ENV PATH="/opt/venv/bin:${PATH}"
WORKDIR /app
COPY --chown=10001:10001 infer.py jfk.flac ./
USER 10001:10001
CMD ["python", "infer.py"]
