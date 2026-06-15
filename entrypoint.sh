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

# Constrain file permissions to the current execution context user
chmod 600 "$HOME/.local/share/opencode/auth.json"

# Hand over process control to the headless OpenCode server engine
echo "[INFO] Exposing OpenCode routing gateway on 0.0.0.0:4096..."
exec opencode serve --hostname 0.0.0.0 --port 4096
