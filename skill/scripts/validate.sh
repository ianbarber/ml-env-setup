#!/usr/bin/env bash
set -euo pipefail

# Conda-first validation script.
# Run from inside your project dir. It will use ENV_NAME or default ml-<project>.

PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
ENV_NAME="${ENV_NAME:-ml-${PROJECT_NAME}}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== ML Environment Validation (conda) ===${NC}"
echo "Project: $PROJECT_DIR"
echo "Env: $ENV_NAME"
echo

ensure_conda() {
  if command -v conda >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "$HOME/miniforge/etc/profile.d/conda.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/miniforge/etc/profile.d/conda.sh"
  elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
  fi
  command -v conda >/dev/null 2>&1
}

if ! ensure_conda; then
  echo -e "${RED}✗ conda not available${NC}"
  exit 1
fi

echo -e "${GREEN}✓ conda: $(conda --version)${NC}"

if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  echo -e "${RED}✗ env not found: $ENV_NAME${NC}"
  echo "Run setup-universal.sh first (or set ENV_NAME=...)."
  exit 1
fi

echo -e "${GREEN}✓ env exists${NC}"

echo
echo -e "${BLUE}1) Python${NC}"
conda run -n "$ENV_NAME" python --version

echo
echo -e "${BLUE}2) PyTorch${NC}"
conda run -n "$ENV_NAME" python -c "import torch; print('torch', torch.__version__)"

echo
echo -e "${BLUE}3) Backend${NC}"
conda run -n "$ENV_NAME" python - <<'PY'
import torch
print('cuda available:', torch.cuda.is_available())
print('torch.version.cuda:', getattr(torch.version, 'cuda', None))
print('torch.version.hip:', getattr(torch.version, 'hip', None))
if torch.cuda.is_available():
    print('device:', torch.cuda.get_device_name(0))
    print('count:', torch.cuda.device_count())
PY

echo
echo -e "${BLUE}4) Quick matmul${NC}"
conda run -n "$ENV_NAME" python - <<'PY'
import time
import torch

dev = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('device:', dev)

x = torch.randn(1024, 1024, device=dev)
y = torch.randn(1024, 1024, device=dev)

t0 = time.time()
z = x @ y
if dev.type == 'cuda':
    torch.cuda.synchronize()
print('ok', z.shape, 'ms', (time.time()-t0)*1000)
PY

echo
echo -e "${GREEN}=== Validation Complete ===${NC}"
