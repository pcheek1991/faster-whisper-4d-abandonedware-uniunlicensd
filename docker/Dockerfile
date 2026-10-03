FROM nvidia/cuda:13.4.2-cudnn-runtime-ubuntu24.04@sha256:2aa09bb7626c4bff7d0a08b0028edb8dc254d0252a8b67cd386966a864fafac2
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
