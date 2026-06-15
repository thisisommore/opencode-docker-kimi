#!/bin/bash
set -e

# Guard 1: Ensure the server is password-protected
if [ -z "$OPENCODE_SERVER_PASSWORD" ]; then
    echo "=======================================================================" >&2
    echo "[CRITICAL ERROR] OPENCODE_SERVER_PASSWORD environment variable is unset!" >&2
    echo "Aborting startup to prevent unauthenticated server exposure." >&2
    echo "=======================================================================" >&2
    exit 1
fi

# Guard 2: Ensure the identity/API keys are provided
if [ -z "$OPENCODE_AUTH_B64" ]; then
    echo "=======================================================================" >&2
    echo "[CRITICAL ERROR] OPENCODE_AUTH_B64 environment variable is unset!" >&2
    echo "Aborting startup because OpenCode has no configuration profile to load." >&2
    echo "=======================================================================" >&2
    exit 1
fi

# Securely decode runtime configuration payload into the user's home directory
echo "[INFO] Extracting session profiles from OPENCODE_AUTH_B64..."
mkdir -p "$HOME/.local/share/opencode"
echo "$OPENCODE_AUTH_B64" | base64 -d > "$HOME/.local/share/opencode/auth.json"
chmod 600 "$HOME/.local/share/opencode/auth.json"

# --- Dynamic Language Runtime Initializations ---

# 1. Initialize NVM (Brings Node, npm, and pnpm into PATH)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    echo "[INFO] NVM runtime initialized: $(node -v) / pnpm $(pnpm -v)"
fi

# 2. Initialize Rust/Cargo Environment
if [ -s "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
    echo "[INFO] Rust runtime initialized: $(rustc --version)"
fi

# 3. Initialize Bun Environment
export BUN_INSTALL="$HOME/.local/share/bun"
export PATH="$BUN_INSTALL/bin:$PATH"
if command -v bun >/dev/null 2>&1; then
    echo "[INFO] Bun runtime initialized: $(bun -v)"
fi

# Verify system-wide runtimes
echo "[INFO] Go runtime version: $(go version)"
echo "[INFO] Python runtime version: $(python3 --version)"

# Hand over process control to the headless OpenCode server engine
echo "[INFO] Exposing OpenCode routing gateway on 0.0.0.0:4096..."
exec opencode serve --hostname 0.0.0.0 --port 4096
