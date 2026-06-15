# Starting with a lightweight, stable modern LTS system base
FROM ubuntu:24.04

# Suppress frontend warnings during standard package installations
ENV DEBIAN_FRONTEND=noninteractive

# Install initial foundation dependencies for repository mapping
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add official GitHub CLI upstream repository source
RUN mkdir -p -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Update dependencies and assemble the complete Toolbelt + Network Suite + Core Runtimes
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --- System Core & Build Tools ---
    build-essential \
    make \
    git \
    gh \
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
    && rm -rf /var/lib/apt/lists/*

# Install GitLab CLI (glab) natively via official binary stream installer
RUN curl -s https://raw.githubusercontent.com/profclems/glab/trunk/scripts/quick_install.sh | bash

# Map canonical binary alias targets (Fixes Ubuntu's naming quirk for fd-find)
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd

# Install the OpenCode binary natively via the official stream pipe
RUN curl -fsSL https://opencode.ai/install | bash

# Enforce secure unprivileged runtime boundaries (UID 1001) for low-permission host servers
RUN useradd -m -u 1001 -s /bin/bash developer && \
    mkdir -p /workspace /home/developer/.local/share/opencode && \
    chown -R developer:developer /workspace /home/developer

# Configure user context parameters
WORKDIR /workspace
USER developer

# Set up explicit environment anchors for user-space package manager installations
ENV NVM_DIR=/home/developer/.nvm
ENV CARGO_HOME=/home/developer/.cargo
ENV BUN_INSTALL=/home/developer/.local/share/bun
ENV PATH="${CARGO_HOME}/bin:${BUN_INSTALL}/bin:${PATH}"

# 1. Install Node.js via NVM + Global pnpm (All inside user space)
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default 'lts/*' \
    && npm install -g pnpm

# 2. Install Rust Toolchain via rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

# 3. Install Bun Runtime
RUN curl -fsSL https://bun.sh/install | bash

# Inject the environment controller script
COPY --chown=developer:developer entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose standard headless routing network definitions
EXPOSE 4096

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
