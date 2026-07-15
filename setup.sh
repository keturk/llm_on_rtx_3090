#!/bin/bash
# Machine-detecting setup / verification entry point.
#
# Detects which supported machine this is and routes to the right path:
#   - ARM (aarch64) + native Ollama  -> ASUS GX10 (systemd, unified memory)
#   - x86-64 + Docker                -> Dell T5820 (Ollama in Docker + Forge)
#
# See docs/MACHINES.md for the full comparison.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- pretty helpers ---------------------------------------------------------
c_ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
c_warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
c_err()  { printf '  \033[31m✗\033[0m %s\n' "$1"; }
hr()     { printf '%s\n' "----------------------------------------------------------------------"; }

ARCH="$(uname -m)"

echo
echo "🔎 Detecting machine…"
echo "   arch: $ARCH"

# --- GX10 path: ARM + native Ollama ----------------------------------------
setup_gx10() {
    hr
    echo "🖥️  Detected: ASUS GX10 class (ARM / native Ollama)"
    echo "    Guide: docs/machines/gx10/README.md"
    hr
    local ok=1

    echo "GPU:"
    if command -v nvidia-smi >/dev/null 2>&1; then
        local gpu
        gpu="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || true)"
        [ -n "$gpu" ] && c_ok "nvidia-smi: ${gpu}" || { c_warn "nvidia-smi present but no GPU reported"; }
    else
        c_err "nvidia-smi not found"; ok=0
    fi

    echo "Ollama (native):"
    if command -v ollama >/dev/null 2>&1; then
        c_ok "ollama binary: $(ollama --version 2>/dev/null | head -1)"
    else
        c_err "ollama not installed — install the arm64 build: curl -fsSL https://ollama.com/install.sh | sh"
        ok=0
    fi

    local unit_files
    unit_files="$(systemctl list-unit-files 2>/dev/null || true)"
    if grep -q '^ollama\.service' <<<"$unit_files"; then
        if [ "$(systemctl is-active ollama 2>/dev/null || true)" = "active" ]; then
            c_ok "ollama.service is active"
        else
            c_warn "ollama.service exists but is not active — start it: sudo systemctl start ollama"
        fi
        local host models
        host="$(systemctl show ollama -p Environment 2>/dev/null | grep -o 'OLLAMA_HOST=[^ ]*' || true)"
        models="$(systemctl show ollama -p Environment 2>/dev/null | grep -o 'OLLAMA_MODELS=[^ ]*' || true)"
        [ -n "$host" ]   && c_ok "$host"   || c_warn "OLLAMA_HOST not set (defaults to 127.0.0.1:11434)"
        [ -n "$models" ] && c_ok "$models" || c_warn "OLLAMA_MODELS not set (defaults to ~/.ollama)"
    else
        c_warn "no ollama systemd service found (running ollama serve manually?)"
    fi

    echo "Model store:"
    local mdir="/opt/models" msize
    if [ -d "$mdir" ]; then
        msize="$(du -sh "$mdir" 2>/dev/null | cut -f1)"
        c_ok "$mdir (${msize:-?} used)"
    else
        c_warn "$mdir not found — create it: sudo mkdir -p $mdir && sudo chown -R ollama:ollama $mdir"
    fi

    echo "API:"
    if curl -sf http://127.0.0.1:11500/api/version >/dev/null 2>&1; then
        c_ok "server responds on :11500 (native)"
    elif curl -sf http://127.0.0.1:11434/api/version >/dev/null 2>&1; then
        c_ok "server responds on :11434 (proxy/default)"
    else
        c_warn "no Ollama API on :11500 or :11434 — is the service running?"
    fi

    hr
    if [ "$ok" -eq 1 ]; then
        echo "✅ GX10 environment looks good."
    else
        echo "⚠️  GX10 environment has gaps (see ✗ above)."
    fi
    cat <<'EOF'

Next steps:
  ollama list                                   # installed models
  ollama run nemotron-3-nano:30b "Hello!"       # no docker exec needed
  ollama pull qwen3:14b                          # download a model

Docs: docs/machines/gx10/Setup.md
EOF
}

# --- T5820 path: x86 + Docker ----------------------------------------------
setup_t5820() {
    hr
    echo "🖥️  Detected: Dell T5820 class (x86-64 / Ollama in Docker)"
    echo "    Guide: docs/machines/t5820/README.md"
    hr
    if command -v ollama >/dev/null 2>&1 && systemctl is-active --quiet ollama 2>/dev/null; then
        c_warn "A native ollama service is also active on this x86 box — the T5820 path uses Docker."
    fi
    if [ -x "$REPO_DIR/llm-docker/setup.sh" ]; then
        echo "Delegating to the Docker setup (llm-docker/setup.sh)…"
        echo
        cd "$REPO_DIR/llm-docker"
        exec ./setup.sh
    else
        c_err "llm-docker/setup.sh not found or not executable."
        echo "  See docs/machines/t5820/System_Setup.md and Install.md."
        exit 1
    fi
}

# --- route ------------------------------------------------------------------
case "$ARCH" in
    aarch64|arm64)
        setup_gx10
        ;;
    x86_64|amd64)
        setup_t5820
        ;;
    *)
        hr
        c_warn "Unrecognized architecture '$ARCH'."
        echo "  This repo is tested on:"
        echo "    - aarch64 (ASUS GX10 / GB10, native Ollama)  -> docs/machines/gx10/"
        echo "    - x86_64  (Dell T5820 / RTX 3090, Docker)     -> docs/machines/t5820/"
        echo "  See docs/MACHINES.md to pick the closest path."
        exit 1
        ;;
esac
