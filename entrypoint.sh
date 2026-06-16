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

# --- Git Configuration Setup ---
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
    echo "[INFO] Configuring global Git commit author identity..."
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
else
    echo "[WARNING] GIT_USER_NAME or GIT_USER_EMAIL is unset. Git commits may complain about identity." >&2
fi

# Generate Ed25519 key pair only if it doesn't exist (Idempotent for volume restarts)
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo "[INFO] No existing deployment key detected. Provisioning fresh Ed25519 pair..."
    ssh-keygen -t ed25519 -C "${GIT_USER_EMAIL:-opencode-agent}" -N "" -f "$HOME/.ssh/id_ed25519"
fi

# Initialize runtime container SSH agent background process
echo "[INFO] Spawning background SSH agent..."
eval "$(ssh-agent -s)"

# Register key with the running agent boundary
ssh-add "$HOME/.ssh/id_ed25519"

# Print public signature block so it can be registered at the forge layer easily
echo "======================================================================="
echo "[ACTION REQUIRED] Copy this public signature to your GitHub/GitLab keys:"
cat "$HOME/.ssh/id_ed25519.pub"
echo "======================================================================="

# --- Safe Language Runtime Initialization Diagnostics ---
go version >/dev/null 2>&1 && echo "[INFO] Go runtime version: $(go version)" || echo "[WARN] Go runtime not explicitly tracked"
python3 --version >/dev/null 2>&1 && echo "[INFO] Python runtime version: $(python3 --version)" || echo "[WARN] Python runtime not explicitly tracked"

if command -v node >/dev/null 2>&1; then
    echo "[INFO] Persistent Node runtime initialized: $(node -v)"
    echo "[INFO] Persistent pnpm runtime version: $(pnpm -v)"
fi

# Hand over process control to the headless OpenCode server engine
echo "[INFO] Exposing OpenCode routing gateway on 0.0.0.0:4096..."
exec opencode serve --hostname 0.0.0.0 --port 4096
