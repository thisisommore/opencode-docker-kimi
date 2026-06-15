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

# Securely decode runtime configuration payload using printf to avoid trailing newlines
echo "[INFO] Extracting session profiles from OPENCODE_AUTH_B64..."
mkdir -p "$HOME/.local/share/opencode"
printf '%s' "$OPENCODE_AUTH_B64" | base64 -d > "$HOME/.local/share/opencode/auth.json"
chmod 600 "$HOME/.local/share/opencode/auth.json"

# --- Safe Language Runtime Initialization Diagnostics ---
# Wrapped to prevent set -e from aborting startup if an individual tool isn't in focus
go version >/dev/null 2>&1 && echo "[INFO] Go runtime version: $(go version)" || echo "[WARN] Go runtime not explicitly tracked in environment"
python3 --version >/dev/null 2>&1 && echo "[INFO] Python runtime version: $(python3 --version)" || echo "[WARN] Python runtime not explicitly tracked in environment"

if command -v node >/dev/null 2>&1; then
    echo "[INFO] Persistent Node runtime initialized: $(node -v)"
    echo "[INFO] Persistent pnpm runtime version: $(pnpm -v)"
fi

if command -v rustc >/dev/null 2>&1; then
    echo "[INFO] Rust toolchain initialized: $(rustc --version)"
fi

if command -v bun >/dev/null 2>&1; then
    echo "[INFO] Bun engine initialized: $(bun -v)"
fi

# Hand over process control to the headless OpenCode server engine
echo "[INFO] Exposing OpenCode routing gateway on 0.0.0.0:4096..."
exec opencode serve --hostname 0.0.0.0 --port 4096
