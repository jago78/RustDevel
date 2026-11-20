FROM rust:1-bookworm

# --- Node.js (required to install the OpenCode CLI) ---
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Useful build deps for Rust projects (adjust as needed) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    git \
    ca-certificates \
    build-essential \
    jq \
    grep \
    findutils \
    && rm -rf /var/lib/apt/lists/*

# --- Rust components ---
RUN rustup component add rustfmt clippy rust-analyzer

# Install task command for running CI tasks
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# --- OpenCode CLI ---
RUN npm install -g @opencode/cli

# --- Non-root user with host-matching UID/GID ---
ARG DEVEL_UID=1000
ARG DEVEL_GID=1000

RUN groupadd -g "${DEVEL_GID}" devel \
    && useradd -u "${DEVEL_UID}" -g "${DEVEL_GID}" -m -s /bin/bash devel \
    && chown -R "${DEVEL_UID}:${DEVEL_GID}" /usr/local/cargo

USER devel
WORKDIR /home/devel

# Install OpenCode config
RUN mkdir -p /home/devel/.config/opencode
COPY opencode/ /home/devel/.config/opencode/

# Install Git config
RUN mkdir --mode 700 /home/devel/.ssh
COPY --chown=devel:devel --chmod=600 ssh_config /home/devel/.ssh/config

ENV CARGO_HOME=

