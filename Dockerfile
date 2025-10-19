# syntax=docker/dockerfile:1
# Using TensorRT 8.6.1 with Python 3.10 support via conda
FROM nvcr.io/nvidia/tensorrt:23.08-py3

# Install miniconda
RUN curl -o ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

ENV PATH=/opt/conda/bin:$PATH

# Accept Anaconda Terms of Service for non-interactive environments
# See: https://www.anaconda.com/docs/getting-started/tos-plugin
ENV CONDA_PLUGINS_AUTO_ACCEPT_TOS=true

# System deps:
# - ffmpeg for video
# - build tools for packages with native extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    ffmpeg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone Ditto TalkingHead
RUN git clone --depth=1 https://github.com/antgroup/ditto-talkinghead /app/ditto-talkinghead

# Create conda environment with Python 3.10 and exact numpy version from conda-forge
RUN conda create -n ditto python=3.10 -y && \
    conda install -n ditto -c conda-forge numpy=2.0.1 -y

# Activate conda environment and install dependencies
SHELL ["conda", "run", "-n", "ditto", "/bin/bash", "-c"]

# Install PyTorch with CUDA 11.8
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install TensorRT and other Python dependencies
RUN pip install --no-cache-dir \
    tensorrt==8.6.1 \
    librosa \
    tqdm \
    filetype \
    imageio \
    opencv-python-headless \
    scikit-image \
    cython \
    cuda-python==12.2.0 \
    imageio-ffmpeg \
    colored \
    polygraphy \
    soundfile \
    pyyaml

# Entry and mounts
RUN mkdir -p /app/checkpoints
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Make Ditto importable
ENV PYTHONPATH=/app/ditto-talkinghead

# Work in the repo for inference.py
WORKDIR /app/ditto-talkinghead

# Ensure conda environment is activated on container start
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "ditto", "/app/entrypoint.sh"]