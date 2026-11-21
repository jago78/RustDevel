FROM ubuntu:24.04

# --- Base packages (git, build deps for Rust projects, misc CLI tools) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    jq \
    grep \
    findutils \
    ripgrep \
    less \
    tmux \
    gdb \
    fzf \
    bat \
    htop \
    openssh-client \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/batcat /usr/local/bin/bat

# --- Node.js (required to install the OpenCode CLI) ---
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- OpenCode CLI ---
RUN npm install -g @opencode/cli

# --- Task CLI, used for `task ci:build` / `task ci:test` / `task ci:pipeline` ---
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# --- Non-root user with host-matching UID/GID ---
ARG DEVEL_UID=1001
ARG DEVEL_GID=1001

RUN groupadd -g "${DEVEL_GID}" devel \
    && useradd -u "${DEVEL_UID}" -g "${DEVEL_GID}" -m -s /bin/bash devel

USER devel

# --- Rust toolchain (stable, installed as devel, never as root) ---
# Set as real container ENV (not just a .bashrc/.profile append) so the
# toolchain is on PATH for every process in this container, including
# opencode's shell tool, which runs non-interactive/non-login shells that
# don't source rc files.
ENV RUSTUP_HOME=/home/devel/.rustup
ENV CARGO_HOME=/home/devel/.cargo
ENV PATH=/home/devel/.cargo/bin:$PATH
ENV DISABLE_AUTOUPDATER=1

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --profile default \
    && rustup component add rustfmt clippy rust-analyzer

# --- OpenCode config: minimal, OpenAI-backed, key supplied via env ---
COPY --chown=${DEVEL_UID}:${DEVEL_GID} opencode/opencode.jsonc /home/devel/.config/opencode/opencode.jsonc

# --- SSH config: Required for Coder Git Clone plugin to work
RUN mkdir --mode 700 /home/devel/.ssh
COPY --chown=devel:devel --chmod=600 ssh_config /home/devel/.ssh/config

WORKDIR /home/devel

