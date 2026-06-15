# Starting with a lightweight, stable modern LTS system base
FROM ubuntu:24.04

# Suppress frontend warnings during standard package installations
ENV DEBIAN_FRONTEND=noninteractive

# Update dependencies and assemble the complete AI toolbelt (rg, fd, git, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    ripgrep \
    fd-find \
    jq \
    tmux \
    htop \
    build-essential \
    make \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

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

# Inject the environment controller script
COPY --chown=developer:developer entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose standard headless routing network definitions
EXPOSE 4096

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
