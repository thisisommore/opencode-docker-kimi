# Starting with a lightweight, stable modern LTS system base
FROM ubuntu:24.04

# Suppress frontend warnings during standard package installations
ENV DEBIAN_FRONTEND=noninteractive

# Update dependencies and assemble the complete Toolbelt + Network Suite + Core Runtimes
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --- System Core & Fetch Utilities ---
    curl \
    wget \
    ca-certificates \
    git \
    openssh-client \
    build-essential \
    make \
    ripgrep \
    fd-find \
    jq \
    tmux \
    htop \
    # --- Python & Go Runtimes (System-Wide) ---
    python3 \
    python3-pip \
    python3-venv \
    golang-go \
    # --- Network & Port Checking Toolkit ---
    iproute2 \
    netcat-openbsd \
    iputils-ping \
    dnsutils \
    net-tools \
    nmap \
    # --- Archiving & Compression Tools ---
    tar \
    gzip \
    bzip2 \
    zip \
    unzip \
    xz-utils \
    zstd \
    # --- Binary Inspection Tooling ---
    file \
    xxd \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# Map canonical binary alias targets (Fixes Ubuntu's naming quirk for fd-find)
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd

# Enforce secure unprivileged runtime boundaries (UID 1001) for low-permission host servers
RUN useradd -m -u 1001 -s /bin/bash developer && \
    mkdir -p /workspace /home/developer/.local/share/opencode /home/developer/.local/bin && \
    chown -R developer:developer /workspace /home/developer

# Configure user context parameters
WORKDIR /workspace
USER developer

# Set up global environment paths for all ecosystem tooling runtimes
ENV NVM_DIR=/home/developer/.nvm
ENV CARGO_HOME=/home/developer/.cargo
ENV BUN_INSTALL=/home/developer/.local/share/bun
ENV PATH="/home/developer/.local/bin:/home/developer/.opencode/bin:${CARGO_HOME}/bin:${BUN_INSTALL}/bin:${PATH}"

# Install the OpenCode binary cleanly within the developer's execution context
RUN curl -fsSL https://opencode.ai/install | bash

# Install Node.js via NVM + Global pnpm, then symlink them to break subshell path dependency issues
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default 'lts/*' \
    && npm install -g pnpm \
    && ln -s "$(which node)" /home/developer/.local/bin/node \
    && ln -s "$(which npm)" /home/developer/.local/bin/npm \
    && ln -s "$(which pnpm)" /home/developer/.local/bin/pnpm

# Install Rust Toolchain via rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

# Install Bun Runtime
RUN curl -fsSL https://bun.sh/install | bash

# Inject the fixed environment controller entrypoint script
COPY --chown=developer:developer entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose standard headless routing network definitions
EXPOSE 4096

mkdir -p /home/developer/Documents/git
WORKDIR /home/developer/Documents/git

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
