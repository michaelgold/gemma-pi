FROM ghcr.io/ggml-org/llama.cpp:server-cuda AS build-base

ARG PYTHON_VER=3.13.13
WORKDIR /tmp/python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libffi-dev \
    liblzma-dev \
    tk-dev \
    xz-utils \
    wget \
    && rm -rf /var/lib/apt/lists/*
ADD https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz .
RUN tar xzf Python-${PYTHON_VER}.tgz && cd Python-${PYTHON_VER} && \
    ./configure --enable-shared --enable-loadable-sqlite-extensions && \
    make -j"$(nproc)" && make install && ldconfig && \
    ln -sf /usr/local/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/local/bin/pip3 /usr/local/bin/pip

FROM ghcr.io/ggml-org/llama.cpp:server-cuda
ENV LD_LIBRARY_PATH=/usr/local/lib:/app:/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    libgomp1 \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build-base /usr/local /usr/local

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN python --version && pip --version && \
    wget -q https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz && \
    mkdir -p uv-extract && tar -xzf uv-x86_64-unknown-linux-gnu.tar.gz -C uv-extract && \
    cp uv-extract/uv-x86_64-unknown-linux-gnu/uv /usr/local/bin/uv && \
    cp uv-extract/uv-x86_64-unknown-linux-gnu/uvx /usr/local/bin/uvx && \
    chmod +x /usr/local/bin/uv /usr/local/bin/uvx && rm -rf uv-extract *.tar.gz
RUN npm install -g @mariozechner/pi-coding-agent

COPY docker/gemma4-entrypoint.sh /usr/local/bin/gemma4-entrypoint.sh
COPY docker/pi-agent-entrypoint.sh /usr/local/bin/pi-agent-entrypoint.sh
COPY docker/pi-gemma4-models.compose.json /usr/local/share/pi-gemma4-models.json

RUN chmod +x /usr/local/bin/gemma4-entrypoint.sh /usr/local/bin/pi-agent-entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/pi-agent-entrypoint.sh"]
CMD ["pi", "--model", "gemma-4-e4b-it"]