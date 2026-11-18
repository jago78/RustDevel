FROM rust:1-bookworm

# --- Node.js (required to install the Claude Code CLI) ---
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

# --- Claude Code CLI ---
RUN npm install -g @anthropic-ai/claude-code

# --- Non-root user with host-matching UID/GID ---
ARG DEVEL_UID=1000
ARG DEVEL_GID=1000

RUN groupadd -g "${DEVEL_GID}" devel \
    && useradd -u "${DEVEL_UID}" -g "${DEVEL_GID}" -m -s /bin/bash devel \
    && mkdir -p /workspace \
    && chown -R "${DEVEL_UID}:${DEVEL_GID}" /workspace /usr/local/cargo

USER devel
WORKDIR /workspace

COPY claude.json /home/devel/.claude.json
RUN mkdir /home/devel/.claude

ENV CARGO_HOME=
ENV DISABLE_AUTOUPDATER=1

