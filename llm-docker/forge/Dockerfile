FROM nvidia/cuda:12.8.0-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    git wget curl \
    build-essential gcc g++ \
    libjpeg-dev libpng-dev libtiff-dev libwebp-dev zlib1g-dev libfreetype-dev \
    libgl1 libglx-mesa0 libglib2.0-0 libsm6 libxext6 libxrender1 \
    libgoogle-perftools-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git /app

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7860

ENTRYPOINT ["/entrypoint.sh"]
