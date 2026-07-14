#!/bin/bash
set -e

VENV_DIR="/app/venv"

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "=== First run: creating virtual environment ==="
    echo "This will take 5-10 minutes to install PyTorch and dependencies..."
    rm -rf "$VENV_DIR"/* "$VENV_DIR"/.[!.]* 2>/dev/null || true
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

if ! python3 -c "import torch" 2>/dev/null; then
    echo "=== Installing PyTorch and dependencies ==="
    pip install --upgrade pip setuptools wheel
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
    pip install xformers
fi

# Pre-install CLIP with setuptools available (avoids pkg_resources error in build isolation)
if ! python3 -c "import clip" 2>/dev/null; then
    echo "=== Installing CLIP ==="
    pip install setuptools
    pip install --no-build-isolation https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip
fi

# Fix compatibility issues
pip install "numpy<2" "scikit-image>=0.22" joblib --quiet 2>/dev/null || true

cd /app

python3 launch.py \
    --listen \
    --port 7860 \
    --api \
    --xformers \
    --skip-torch-cuda-test \
    --skip-python-version-check \
    --no-download-sd-model \
    --enable-insecure-extension-access \
    ${FORGE_ARGS:-}
